import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/task/duration/model/task_duration_entity.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:uuid/uuid.dart';

part 'task_new_state.dart';

class TaskNewCubit extends HydratedCubit<TaskNewState> {
  TaskNewCubit({
    required TasksRepository tasksRepository,
    TaskEntity? initialTask,
    Jiffy? dueAt,
  }) : _tasksRepository = tasksRepository,
       super(
         TaskNewState.fromData(task: initialTask, dueAt: dueAt),
       );

  final TasksRepository _tasksRepository;

  @override
  TaskNewState? fromJson(Map<String, dynamic> json) {
    return state.copyWith(
      title: json['title'] as String? ?? '',
      priority:
          TaskPriority.fromValue(json['priority'] as int?) ?? TaskPriority.none,
      isAllDay: json['isAllDay'] as bool? ?? false,
      recurrenceRule: json['recurrenceRule'] != null
          ? () => RecurrenceRule.fromJson(
              json['recurrenceRule'] as Map<String, dynamic>,
            )
          : null,
      alarms: json['alarms'] != null
          ? (json['alarms'] as List<dynamic>)
                .map((e) => EventAlarm.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>)
                .map((e) => TagEntity.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      children: json['children'] != null
          ? (json['children'] as List<dynamic>)
                .map((e) => TaskEntity.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  @override
  Map<String, dynamic>? toJson(TaskNewState state) {
    // 只在创建新任务时保存草稿（initialTask == null）
    if (state.initialTask != null) {
      return null; // 不保存编辑模式的状态
    }
    // 只在有实际内容时保存
    if (state.title.isEmpty && state.tags.isEmpty) {
      return null; // 空状态不保存
    }

    return {
      'title': state.title,
      'priority': state.priority.value,
      'isAllDay': state.isAllDay,
      if (state.recurrenceRule != null)
        'recurrenceRule': state.recurrenceRule!.toJson(),
      if (state.alarms.isNotEmpty)
        'alarms': state.alarms.map((e) => e.toJson()).toList(),
      if (state.tags.isNotEmpty)
        'tags': state.tags.map((e) => e.toJson()).toList(),
      if (state.children.isNotEmpty)
        'children': state.children.map((e) => e.toJson()).toList(),
    };
  }

  void onFocusChanged(TaskNewFocus focus) {
    if (focus == TaskNewFocus.time) {
      if (state.startAt == null || state.endAt == null) {
        final now = Jiffy.now().startOf(Unit.minute);
        emit(
          state.copyWith(
            focus: TaskNewFocus.time,
            startAt: () => now,
            endAt: () => now.add(hours: 1),
          ),
        );
        return;
      }
    }
    if (focus == TaskNewFocus.recurrence) {
      if (state.recurrenceRule == null) {
        const recurrenceRule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
        );
        emit(
          state.copyWith(
            focus: TaskNewFocus.recurrence,
            recurrenceRule: () => recurrenceRule,
          ),
        );
        return;
      }
    }
    emit(state.copyWith(focus: focus));
  }

  void onTitleChanged(String title) {
    emit(state.copyWith(title: title));
  }

  void onPriorityChanged(TaskPriority priority) {
    emit(state.copyWith(priority: priority));
  }

  void onTagsChanged(List<TagEntity> tags) {
    emit(state.copyWith(tags: tags));
  }

  void onDurationChanged(TaskDurationEntity? entity) {
    emit(
      state.copyWith(
        startAt: () => entity?.startAt,
        endAt: () => entity?.endAt,
        isAllDay: entity?.isAllDay,
      ),
    );
  }

  void onStartAtChanged(Jiffy? startAt) {
    Jiffy? endAt;
    if (startAt == null) {
      endAt = null;
    } else if (state.endAt != null && state.endAt!.isBefore(startAt)) {
      endAt = state.isAllDay ? null : startAt.add(hours: 1);
    } else {
      endAt = state.endAt;
    }
    emit(state.copyWith(startAt: () => startAt, endAt: () => endAt));
  }

  void onEndAtChanged(Jiffy? endAt) {
    emit(state.copyWith(endAt: () => endAt?.endOf(Unit.day)));
  }

  void onRecurrenceRuleChanged(RecurrenceRule? recurrenceRule) {
    emit(state.copyWith(recurrenceRule: () => recurrenceRule));
  }

  void onAlarmsChanged(List<EventAlarm> alarms) {
    emit(state.copyWith(alarms: alarms));
  }

  void onChildrenChanged(List<TaskEntity> children) {
    emit(state.copyWith(children: children));
  }

  Future<void> onSave() async {
    emit(state.copyWith(status: PageStatus.loading));

    final initialTask = state.initialTask;
    if (initialTask == null) {
      final task = Task(
        id: const Uuid().v4(),
        title: state.title,
        priority: state.priority,
        dueAt: state.startAt?.startOf(Unit.day),
        startAt: state.startAt,
        endAt: state.endAt ?? state.startAt?.endOf(Unit.day),
        recurrenceRule: state.recurrenceRule,
        order: 0,
        isAllDay: state.isAllDay,
        alarms: state.alarms,
        createdAt: Jiffy.now(),
        layer: 0,
        childCount: 0,
      );
      await _tasksRepository.create(
        task: task,
        tags: state.tags,
        children: state.children,
      );
      await clear();
      // clear() 只清除持久化存储，需要手动重置状态
      emit(const TaskNewState(status: PageStatus.success));
      unawaited(AlarmNotificationService.instance.scheduleForTask(task));
      return;
    }

    final need = await _tasksRepository.needsEditModeSelection(initialTask);
    if (need) {
      emit(state.copyWith(showEditModeSelection: true));
    } else {
      await onEditModeSelected(RecurringTaskEditMode.allEvents);
    }
  }

  Future<void> onEditModeSelected(RecurringTaskEditMode? editMode) async {
    if (editMode == null) {
      emit(state.copyWith(showEditModeSelection: false));
      return;
    }

    final initialTask = state.initialTask;
    if (initialTask == null) return;

    final task = Task(
      id: initialTask.id,
      title: state.title,
      priority: state.priority,
      dueAt: state.startAt?.startOf(Unit.day),
      startAt: state.startAt,
      endAt: state.endAt ?? state.startAt?.endOf(Unit.day),
      order: initialTask.order,
      isAllDay: state.isAllDay,
      alarms: state.alarms,
      parentId: initialTask.parentId,
      recurrenceRule: state.recurrenceRule,
      createdAt: initialTask.createdAt,
      updatedAt: Jiffy.now(),
      layer: 0,
      childCount: 0,
    );
    emit(state.copyWith(status: PageStatus.loading));
    await _tasksRepository.updateWithEditMode(
      entity: initialTask,
      task: task,
      editMode: editMode,
      tags: state.tags,
      children: state.children,
      occurrenceAt: initialTask.occurrence?.occurrenceAt,
    );
    unawaited(AlarmNotificationService.instance.scheduleForTask(task));
    emit(state.copyWith(status: PageStatus.success));
  }
}
