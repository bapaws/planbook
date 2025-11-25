import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:table_calendar/table_calendar.dart';

part 'task_today_state.dart';

class TaskTodayCubit extends Cubit<TaskTodayState> {
  TaskTodayCubit() : super(TaskTodayState(date: Jiffy.now().startOf(Unit.day)));

  void onDateSelected(Jiffy date) {
    emit(state.copyWith(date: date.startOf(Unit.day)));
  }

  void onCalendarFormatChanged(CalendarFormat calendarFormat) {
    emit(state.copyWith(calendarFormat: calendarFormat));
  }
}
