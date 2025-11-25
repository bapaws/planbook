import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_picker_event.dart';
part 'task_picker_state.dart';

class TaskPickerBloc extends Bloc<TaskPickerEvent, TaskPickerState> {
  TaskPickerBloc({
    required TasksRepository tasksRepository,
  }) : _tasksRepository = tasksRepository,
       super(const TaskPickerState()) {
    on<TaskPickerInboxRequested>(_onInboxRequested);
    on<TaskPickerTodayRequested>(_onTodayRequested);
  }

  final TasksRepository _tasksRepository;

  Future<void> _onInboxRequested(
    TaskPickerInboxRequested event,
    Emitter<TaskPickerState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _tasksRepository.getAllInboxTodayTaskEntities(),
      onData: (tasks) => state.copyWith(
        status: PageStatus.success,
        inboxTasks: tasks,
      ),
    );
  }

  Future<void> _onTodayRequested(
    TaskPickerTodayRequested event,
    Emitter<TaskPickerState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _tasksRepository.getAllTodayTaskEntities(),
      onData: (tasks) => state.copyWith(
        status: PageStatus.success,
        todayTasks: tasks,
      ),
    );
  }
}
