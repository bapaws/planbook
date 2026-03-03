part of 'task_today_bloc.dart';

sealed class TaskTodayEvent extends Equatable {
  const TaskTodayEvent();

  @override
  List<Object?> get props => [];
}

final class TaskTodayDateSelected extends TaskTodayEvent {
  const TaskTodayDateSelected({required this.date, this.isCompleted});

  final Jiffy date;
  final bool? isCompleted;

  @override
  List<Object?> get props => [date, isCompleted];
}

final class TaskTodayCalendarFormatChanged extends TaskTodayEvent {
  const TaskTodayCalendarFormatChanged({required this.calendarFormat});

  final CalendarFormat calendarFormat;

  @override
  List<Object?> get props => [calendarFormat];
}

final class TaskTodayFocusNoteRequested extends TaskTodayEvent {
  const TaskTodayFocusNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

final class TaskTodaySummaryNoteRequested extends TaskTodayEvent {
  const TaskTodaySummaryNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

final class TaskTodayNoteTaskAppended extends TaskTodayEvent {
  const TaskTodayNoteTaskAppended({
    required this.task,
    required this.noteType,
  });

  final TaskEntity task;
  final NoteType noteType;

  @override
  List<Object?> get props => [task, noteType];
}
