import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'root_task_event.dart';
part 'root_task_state.dart';

class RootTaskBloc extends HydratedBloc<RootTaskEvent, RootTaskState> {
  RootTaskBloc({
    required TasksRepository tasksRepository,
  }) : _tasksRepository = tasksRepository,
       super(const RootTaskState()) {
    on<RootTaskTabSelected>(_onTabSelected);
    on<RootTaskTagSelected>(_onTagSelected);
    on<RootTaskTaskCountRequested>(
      _onTaskCountRequested,
      transformer: concurrent(),
    );

    on<RootTaskViewTypeChanged>(_onViewTypeChanged);
    on<RootTaskShowCompletedChanged>(_onShowCompletedChanged);
  }

  final TasksRepository _tasksRepository;

  bool? get isCompleted => state.isCompleted;

  @override
  RootTaskState? fromJson(Map<String, dynamic> json) {
    return RootTaskState(
      status: PageStatus.values.byName(json['status'] as String),
      tab: TaskListMode.values.byName(json['tab'] as String),
      viewType: RootTaskViewType.values.byName(json['viewType'] as String),
      tag: json['tag'] != null
          ? TagEntity.fromJson(json['tag'] as Map<String, dynamic>)
          : null,
      showCompleted: json['showCompleted'] as bool,
    );
  }

  @override
  Map<String, dynamic>? toJson(RootTaskState state) {
    return {
      'status': state.status.name,
      'tab': state.tab.name,
      'viewType': state.viewType.name,
      'showCompleted': state.showCompleted,
      'tag': state.tag?.toJson(),
    };
  }

  Future<void> _onTabSelected(
    RootTaskTabSelected event,
    Emitter<RootTaskState> emit,
  ) async {
    emit(state.copyWith(tab: event.tab));
  }

  Future<void> _onTagSelected(
    RootTaskTagSelected event,
    Emitter<RootTaskState> emit,
  ) async {
    emit(state.copyWith(tab: TaskListMode.tag, tag: event.tag));
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

  Future<void> _onViewTypeChanged(
    RootTaskViewTypeChanged event,
    Emitter<RootTaskState> emit,
  ) async {
    final newViewType =
        event.viewType ??
        RootTaskViewType.values[(state.viewType.index + 1) %
            RootTaskViewType.values.length];
    emit(state.copyWith(viewType: newViewType));
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
}
