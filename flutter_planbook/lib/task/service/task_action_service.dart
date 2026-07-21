import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:uuid/uuid.dart';

/// 统一处理 Task 相关的"完整业务"——把多个 bloc / view 重复编写的
/// 副作用链（更新笔记内容、取消提醒、播放音效、自动笔记等）汇集到一处，
/// 保证所有入口（任务列表、详情、完成页、widget 小组件）行为一致。
///
/// 上层只关心"动作"和"结果"，不再各自拼装提醒 / 笔记 / 音效逻辑。
class TaskActionService {
  TaskActionService({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required SettingsRepository settingsRepository,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _settingsRepository = settingsRepository;

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final SettingsRepository _settingsRepository;

  // ---------------------------------------------------------------------------
  // 完成 / 撤销完成任务
  // ---------------------------------------------------------------------------

  /// 完成（或撤销完成）任务，并触发完整副作用：
  /// - 更新被关联的"重点 / 总结"笔记内容
  /// - 取消每个 activity 对应的本地提醒
  ///
  /// 调用方拿到 activities 后，可以再调 [resolveAutoNote] 处理"自动笔记规则"。
  /// 这里**不**直接处理自动笔记，因为不同入口对返回的 NoteEntity 有不同 UI
  /// 处理（task list / detail 弹编辑器、widget 不弹），需要由调用方决定。
  Future<List<TaskActivity>> completeTask({
    required TaskEntity task,
    Jiffy? completedAt,
    Jiffy? occurrenceAt,
  }) async {
    final activities = await _tasksRepository.completeTask(
      task,
      completedAt: completedAt,
      occurrenceAt: occurrenceAt,
    );
    unawaited(
      _notesRepository.updateTypeNoteContentByTaskActivities(activities),
    );
    for (final activity in activities) {
      final taskId = activity.taskId;
      if (taskId != null) {
        unawaited(AlarmNotificationService.instance.cancelForTask(taskId));
      }
    }
    return activities;
  }

  // ---------------------------------------------------------------------------
  // 删除 / 重新调度提醒
  // ---------------------------------------------------------------------------

  /// 删除任务并取消其提醒。
  Future<void> deleteTask(String taskId) async {
    await _tasksRepository.deleteTaskById(taskId);
    unawaited(AlarmNotificationService.instance.cancelForTask(taskId));
  }

  /// 删除重复任务实例，根据 [mode] 处理：
  /// - thisEventOnly: 软删除该 occurrence，不取消主任务提醒
  /// - thisAndFutureEvents: 结束原重复规则，取消并重新调度提醒
  /// - allEvents: 软删除主任务，取消该任务所有提醒
  Future<void> deleteRecurringTask({
    required TaskEntity entity,
    required RecurringTaskDeleteMode mode,
    Jiffy? occurrenceAt,
  }) async {
    final updatedTask = await _tasksRepository.deleteRecurringTask(
      entity: entity,
      mode: mode,
      occurrenceAt: occurrenceAt,
    );

    switch (mode) {
      case RecurringTaskDeleteMode.thisEventOnly:
        // 不取消主任务提醒；该日 occurrence 仅不在列表显示
        return;
      case RecurringTaskDeleteMode.thisAndFutureEvents:
        unawaited(AlarmNotificationService.instance.cancelForTask(entity.id));
        if (updatedTask != null) {
          unawaited(
            AlarmNotificationService.instance.scheduleForTask(updatedTask),
          );
        }
        return;
      case RecurringTaskDeleteMode.allEvents:
        unawaited(AlarmNotificationService.instance.cancelForTask(entity.id));
        return;
    }
  }

  /// 任务被更新（标题 / 时间 / 重复规则等）后，重新调度本地提醒。
  ///
  /// fire-and-forget，调用方无需 await。
  void rescheduleAlarm(Task task) {
    unawaited(AlarmNotificationService.instance.scheduleForTask(task));
  }

  // ---------------------------------------------------------------------------
  // 自动笔记规则
  // ---------------------------------------------------------------------------

  /// 根据当前 [task] 的 "自动笔记" 规则处理一次完成事件：
  ///
  /// - `none`：什么都不做，返回 null
  /// - `create`：实际创建一条笔记入库，返回 null（无需 UI 弹编辑器）
  /// - `createAndEdit`：创建入库 + 返回完整 NoteEntity 给 UI 弹编辑器
  /// - `edit`：仅返回临时 NoteEntity（不入库），由 UI 弹编辑器后再保存
  ///
  /// [widgetMode] 为 true 时（来自小组件）：因为 widget 进程无法弹编辑器，
  /// `edit` 与 `createAndEdit` 都降级为 `create`。
  Future<NoteEntity?> resolveAutoNote({
    required TaskActivity activity,
    required TaskEntity task,
    Jiffy? createdAt,
    bool widgetMode = false,
  }) async {
    final type = await _settingsRepository.getTaskAutoNoteTypeByTask(task);
    if (type == TaskAutoNoteType.none) return null;

    final effectiveType = widgetMode
        ? (type == TaskAutoNoteType.edit ? TaskAutoNoteType.create : type)
        : type;

    final title = '${activity.deletedAt == null ? '✅' : '❌'} ${task.title}';
    final noteCreatedAt = createdAt ?? Jiffy.now();

    if (effectiveType.isCreate) {
      final note = await _notesRepository.create(
        title: title,
        tags: task.tags,
        taskId: task.id,
        createdAt: noteCreatedAt,
      );
      // widget 模式下 createAndEdit 已被降级为 create，无需返回 NoteEntity
      if (!widgetMode && effectiveType == TaskAutoNoteType.createAndEdit) {
        return _notesRepository.getNoteEntityById(note.id);
      }
      return null;
    }

    if (effectiveType == TaskAutoNoteType.edit) {
      final note = Note(
        id: const Uuid().v4(),
        title: title,
        taskId: task.id,
        createdAt: noteCreatedAt,
        images: const [],
      );
      return NoteEntity(note: note, tags: task.tags);
    }

    return null;
  }

  /// [resolveAutoNote] 的多 activity 版本，按顺序逐个处理，
  /// 返回每个 activity 对应的 NoteEntity（可能为 null）。
  ///
  /// 主要给 widget / 批量完成场景使用。
  Future<List<NoteEntity?>> resolveAutoNotes({
    required Iterable<TaskActivity> activities,
    required TaskEntity task,
    Jiffy? createdAt,
    bool widgetMode = false,
  }) async {
    final results = <NoteEntity?>[];
    for (final activity in activities) {
      results.add(
        await resolveAutoNote(
          activity: activity,
          task: task,
          createdAt: createdAt,
          widgetMode: widgetMode,
        ),
      );
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // 完成反馈：触觉 + 音效
  // ---------------------------------------------------------------------------

  /// 触觉反馈 + 播放完成音效（依赖用户在设置里选择的音效，未选则只触觉）。
  ///
  /// 任意完成任务的入口都可以直接 fire-and-forget 调它。
  Future<void> playCompletedFeedback() async {
    unawaited(HapticFeedback.lightImpact());
    final sound = await _settingsRepository.getTaskCompletedSound();
    if (sound == null || sound.isEmpty) return;
    final player = AudioPlayer();
    await player.play(AssetSource(sound));
  }
}
