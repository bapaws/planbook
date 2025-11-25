import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc({
    required TasksRepository tasksRepository,
    TaskListMode mode = TaskListMode.inbox,
    TagEntity? tag,
  }) : _tasksRepository = tasksRepository,
       _mode = mode,
       super(TaskListState(tag: tag)) {
    on<TaskListRequested>(_onRequested, transformer: restartable());
    on<TaskListCompleted>(_onCompleted);
    on<TaskListDeleted>(_onDeleted);
  }

  final TasksRepository _tasksRepository;
  final TaskListMode _mode;

  Future<void> _onRequested(
    TaskListRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final date = event.date ?? state.date ?? Jiffy.now();
    emit(state.copyWith(status: PageStatus.loading, date: date));
    final stream = _tasksRepository.getTaskEntities(
      mode: _mode,
      date: date,
      tagId: event.tagId,
      priority: event.priority,
    );
    await emit.forEach(
      stream,
      onData: (tasks) => state.copyWith(
        status: PageStatus.success,
        tasks: tasks,
      ),
    );
  }

  Future<void> _onCompleted(
    TaskListCompleted event,
    Emitter<TaskListState> emit,
  ) async {
    await _tasksRepository.completeTaskById(event.taskId);
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _onDeleted(
    TaskListDeleted event,
    Emitter<TaskListState> emit,
  ) async {
    await _tasksRepository.deleteTaskById(event.taskId);
    emit(state.copyWith(status: PageStatus.success));
  }
}
