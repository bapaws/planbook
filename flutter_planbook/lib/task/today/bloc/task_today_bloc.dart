import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:table_calendar/table_calendar.dart';

part 'task_today_event.dart';
part 'task_today_state.dart';

class TaskTodayBloc extends Bloc<TaskTodayEvent, TaskTodayState> {
  TaskTodayBloc({
    required TasksRepository tasksRepository,
  }) : _tasksRepository = tasksRepository,
       super(TaskTodayState(date: Jiffy.now())) {
    on<TaskTodayDateSelected>(_onDateSelected, transformer: restartable());
    on<TaskTodayCalendarFormatChanged>(_onCalendarFormatChanged);
  }

  final TasksRepository _tasksRepository;

  Future<void> _onDateSelected(
    TaskTodayDateSelected event,
    Emitter<TaskTodayState> emit,
  ) async {
    emit(state.copyWith(date: event.date));

    await emit.forEach(
      _tasksRepository.getTaskCount(
        date: event.date,
        mode: TaskListMode.today,
        isCompleted: event.isCompleted,
      ),
      onData: (count) {
        return state.copyWith(
          taskCounts: {...state.taskCounts, event.date.dateKey: count},
        );
      },
    );
  }

  Future<void> _onCalendarFormatChanged(
    TaskTodayCalendarFormatChanged event,
    Emitter<TaskTodayState> emit,
  ) async {
    emit(state.copyWith(calendarFormat: event.calendarFormat));
  }
}
