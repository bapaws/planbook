import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';
import 'package:table_calendar/table_calendar.dart';

part 'task_today_event.dart';
part 'task_today_state.dart';

class TaskTodayBloc extends Bloc<TaskTodayEvent, TaskTodayState> {
  TaskTodayBloc() : super(TaskTodayState(date: Jiffy.now())) {
    on<TaskTodayDateSelected>(_onDateSelected);
    on<TaskTodayCalendarFormatChanged>(_onCalendarFormatChanged);
  }

  Future<void> _onDateSelected(
    TaskTodayDateSelected event,
    Emitter<TaskTodayState> emit,
  ) async {
    emit(state.copyWith(date: event.date));
  }

  Future<void> _onCalendarFormatChanged(
    TaskTodayCalendarFormatChanged event,
    Emitter<TaskTodayState> emit,
  ) async {
    emit(state.copyWith(calendarFormat: event.calendarFormat));
  }
}
