import 'dart:convert';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/week/model/task_week_view_mode.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'root_task_event.dart';
part 'root_task_state.dart';

class RootTaskBloc extends HydratedBloc<RootTaskEvent, RootTaskState> {
  RootTaskBloc({
    required TasksRepository tasksRepository,
    required SettingsRepository settingsRepository,
  }) : _tasksRepository = tasksRepository,
       _settingsRepository = settingsRepository,
       super(const RootTaskState()) {
    on<RootTaskTagToggled>(_onTagToggled);
    on<RootTaskTagsClearedAll>(_onTagsClearedAll);

    on<RootTaskCountRequested>(_onCountRequested);
    on<RootTaskTaskCountRequested>(
      _onTaskCountRequested,
      transformer: concurrent(),
    );

    on<RootTaskDayViewTypeChanged>(_onDayViewTypeChanged);
    on<RootTaskWeekViewModeChanged>(_onWeekViewModeChanged);
    on<RootTaskShowCompletedChanged>(_onShowCompletedChanged);
    on<RootTaskSourcePanelVisibilityChanged>(
      _onSourcePanelVisibilityChanged,
    );
    on<RootTaskPriorityStyleRequested>(_onPriorityStyleRequested);

    on<RootTaskDailyTaskCountRequested>(
      _onDailyTaskCountRequested,
      transformer: concurrent(),
    );
    on<RootTaskTabFocusNoteTypeChanged>(_onTabFocusNoteTypeChanged);

    on<RootTaskRefreshRequested>(_onRefreshRequested);
  }

  final TasksRepository _tasksRepository;
  final SettingsRepository _settingsRepository;

  bool? get isCompleted => state.isCompleted;

  @override
  RootTaskState? fromJson(Map<String, dynamic> json) {
    // 兼容旧键 viewType
    final dayViewTypeName =
        (json['dayViewType'] ?? json['viewType']) as String;
    final dayViewType = RootTaskViewType.values.byName(dayViewTypeName);
    final showSourcePanel = json['showSourcePanel'] as bool? ?? true;
    final weekViewModeName = json['weekViewMode'] as String?;
    return RootTaskState(
      status: PageStatus.values.byName(json['status'] as String),
      dayViewType: dayViewType,
      weekViewMode: weekViewModeName == null
          ? TaskWeekViewMode.grid
          : TaskWeekViewMode.values.byName(weekViewModeName),
      showCompleted: json['showCompleted'] as bool,
      showSourcePanel:
          dayViewType == RootTaskViewType.timeBlock || showSourcePanel,
      tabFocusNoteTypes: json['tabFocusNoteTypes'] == null
          ? const {
              RootTaskTab.day: NoteType.dailyFocus,
              RootTaskTab.week: NoteType.weeklyFocus,
              RootTaskTab.month: NoteType.monthlyFocus,
            }
          : Map<String, dynamic>.from(
              jsonDecode(json['tabFocusNoteTypes'] as String) as Map,
            ).map(
              (key, value) => MapEntry(
                RootTaskTab.values.byName(key),
                value == null ? null : NoteType.values.byName(value as String),
              ),
            ),
    );
  }

  @override
  Map<String, dynamic>? toJson(RootTaskState state) {
    return {
      'status': state.status.name,
      'dayViewType': state.dayViewType.name,
      'weekViewMode': state.weekViewMode.name,
      'showCompleted': state.showCompleted,
      'showSourcePanel': state.showSourcePanel,
      'tabFocusNoteTypes': jsonEncode(
        state.tabFocusNoteTypes.map(
          (key, value) => MapEntry(key.name, value?.name),
        ),
      ),
    };
  }

  Future<void> _onTagToggled(
    RootTaskTagToggled event,
    Emitter<RootTaskState> emit,
  ) async {
    final selectedTagIds = {...state.selectedTagIds};
    if (selectedTagIds.contains(event.tagId)) {
      selectedTagIds.remove(event.tagId);
    } else {
      selectedTagIds.add(event.tagId);
    }
    emit(state.copyWith(selectedTagIds: selectedTagIds));
  }

  Future<void> _onTagsClearedAll(
    RootTaskTagsClearedAll event,
    Emitter<RootTaskState> emit,
  ) async {
    emit(state.copyWith(selectedTagIds: {}));
  }

  Future<void> _onCountRequested(
    RootTaskCountRequested event,
    Emitter<RootTaskState> emit,
  ) async {
    add(const RootTaskTaskCountRequested(mode: TaskListMode.inbox));
    add(const RootTaskTaskCountRequested(mode: TaskListMode.today));
    add(const RootTaskTaskCountRequested(mode: TaskListMode.overdue));
  }

  Future<void> _onTaskCountRequested(
    RootTaskTaskCountRequested event,
    Emitter<RootTaskState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    final stream = _tasksRepository.getTaskCount(
      mode: event.mode,
      isCompleted: false,
    );
    await emit.forEach(
      stream,
      onData: (count) => state.copyWith(
        status: PageStatus.success,
        taskCounts: {
          ...state.taskCounts,
          event.mode: count,
        },
      ),
    );
  }

  Future<void> _onDayViewTypeChanged(
    RootTaskDayViewTypeChanged event,
    Emitter<RootTaskState> emit,
  ) async {
    final newViewType =
        event.dayViewType ??
        RootTaskViewType.values[(state.dayViewType.index + 1) %
            RootTaskViewType.values.length];
    emit(
      state.copyWith(
        dayViewType: newViewType,
        showSourcePanel:
            newViewType == RootTaskViewType.timeBlock || state.showSourcePanel,
      ),
    );
  }

  Future<void> _onWeekViewModeChanged(
    RootTaskWeekViewModeChanged event,
    Emitter<RootTaskState> emit,
  ) async {
    final newViewMode =
        event.weekViewMode ??
        (state.weekViewMode == TaskWeekViewMode.grid
            ? TaskWeekViewMode.list
            : TaskWeekViewMode.grid);
    emit(state.copyWith(weekViewMode: newViewMode));
  }

  Future<void> _onShowCompletedChanged(
    RootTaskShowCompletedChanged event,
    Emitter<RootTaskState> emit,
  ) async {
    emit(
      state.copyWith(
        showCompleted: event.showCompleted ?? !state.showCompleted,
      ),
    );
  }

  Future<void> _onSourcePanelVisibilityChanged(
    RootTaskSourcePanelVisibilityChanged event,
    Emitter<RootTaskState> emit,
  ) async {
    emit(
      state.copyWith(
        showSourcePanel: event.showSourcePanel ?? !state.showSourcePanel,
      ),
    );
  }

  Future<void> _onPriorityStyleRequested(
    RootTaskPriorityStyleRequested event,
    Emitter<RootTaskState> emit,
  ) async {
    await emit.forEach(
      _settingsRepository.onTaskPriorityStyleChange,
      onData: (priorityStyle) => state.copyWith(priorityStyle: priorityStyle),
    );
  }

  Future<void> _onDailyTaskCountRequested(
    RootTaskDailyTaskCountRequested event,
    Emitter<RootTaskState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    final stream = _tasksRepository.getTaskCount(
      date: event.date,
      mode: TaskListMode.today,
    );
    await emit.forEach(
      stream,
      onData: (count) => state.copyWith(
        status: PageStatus.success,
        dailyTaskCounts: {...state.dailyTaskCounts, event.date.dateKey: count},
      ),
    );
  }

  Future<void> _onTabFocusNoteTypeChanged(
    RootTaskTabFocusNoteTypeChanged event,
    Emitter<RootTaskState> emit,
  ) async {
    emit(
      state.copyWith(
        tabFocusNoteTypes: {
          ...state.tabFocusNoteTypes,
          event.tab: event.noteType,
        },
      ),
    );
  }

  Future<void> _onRefreshRequested(
    RootTaskRefreshRequested event,
    Emitter<RootTaskState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    try {
      await _tasksRepository.syncTasks(force: true);
      emit(state.copyWith(status: PageStatus.success));
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('Error syncing tasks: $e');
      }
      emit(state.copyWith(status: PageStatus.failure));
    }
  }
}
