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
  const TaskTodayFocusNoteRequested({required this.date, this.generation});

  final Jiffy date;
  final int? generation;

  @override
  List<Object?> get props => [date, generation];
}

final class TaskTodaySummaryNoteRequested extends TaskTodayEvent {
  const TaskTodaySummaryNoteRequested({required this.date, this.generation});

  final Jiffy date;
  final int? generation;

  @override
  List<Object?> get props => [date, generation];
}

final class TaskTodayNoteTaskAppended extends TaskTodayEvent {
  const TaskTodayNoteTaskAppended({
    required this.task,
    required this.noteType,
    this.target,
  });

  final TaskEntity task;
  final NoteType noteType;
  final PeriodNoteTarget? target;

  @override
  List<Object?> get props => [task, noteType, target];
}
