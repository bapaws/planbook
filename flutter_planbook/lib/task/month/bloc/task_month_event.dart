part of 'task_month_bloc.dart';

sealed class TaskMonthEvent extends Equatable {
  const TaskMonthEvent();

  @override
  List<Object?> get props => [];
}

final class TaskMonthDateSelected extends TaskMonthEvent {
  const TaskMonthDateSelected({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class TaskMonthFocusNoteRequested extends TaskMonthEvent {
  const TaskMonthFocusNoteRequested({required this.date, this.generation});

  final Jiffy date;
  final int? generation;

  @override
  List<Object?> get props => [date, generation];
}

final class TaskMonthSummaryNoteRequested extends TaskMonthEvent {
  const TaskMonthSummaryNoteRequested({required this.date, this.generation});

  final Jiffy date;
  final int? generation;

  @override
  List<Object?> get props => [date, generation];
}

final class TaskMonthCalendarToggled extends TaskMonthEvent {
  const TaskMonthCalendarToggled();
}

final class TaskMonthNoteTaskAppended extends TaskMonthEvent {
  const TaskMonthNoteTaskAppended({
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
