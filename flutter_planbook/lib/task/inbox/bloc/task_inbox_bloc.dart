import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_inbox_event.dart';
part 'task_inbox_state.dart';

class TaskInboxBloc extends Bloc<TaskInboxEvent, TaskInboxState> {
  TaskInboxBloc({
    required TasksRepository tasksRepository,
  }) : _tasksRepository = tasksRepository,
       super(const TaskInboxState()) {
    on<TaskInboxRequested>(_onRequested);
  }

  final TasksRepository _tasksRepository;

  Future<void> _onRequested(
    TaskInboxRequested event,
    Emitter<TaskInboxState> emit,
  ) async {
    await emit.forEach(
      _tasksRepository.getTaskCount(
        mode: TaskListMode.inbox,
        isCompleted: event.isCompleted,
      ),
      onData: (count) => state.copyWith(count: count),
    );
  }
}
