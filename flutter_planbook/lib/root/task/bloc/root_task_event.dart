part of 'root_task_bloc.dart';

sealed class RootTaskEvent extends Equatable {
  const RootTaskEvent();

  @override
  List<Object?> get props => [];
}

final class RootTaskTagSelected extends RootTaskEvent {
  const RootTaskTagSelected({required this.tag});

  final TagEntity tag;

  @override
  List<Object?> get props => [tag];
}

final class RootTaskCountRequested extends RootTaskEvent {
  const RootTaskCountRequested();
}

final class RootTaskTaskCountRequested extends RootTaskEvent {
  const RootTaskTaskCountRequested({required this.mode});

  final TaskListMode mode;

  @override
  List<Object?> get props => [mode];
}

final class RootTaskViewTypeChanged extends RootTaskEvent {
  const RootTaskViewTypeChanged({this.viewType});

  final RootTaskViewType? viewType;

  @override
  List<Object?> get props => [viewType];
}

final class RootTaskShowCompletedChanged extends RootTaskEvent {
  const RootTaskShowCompletedChanged({this.showCompleted});

  final bool? showCompleted;

  @override
  List<Object?> get props => [showCompleted];
}

final class RootTaskPriorityStyleRequested extends RootTaskEvent {
  const RootTaskPriorityStyleRequested();
}

final class RootTaskDailyTaskCountRequested extends RootTaskEvent {
  const RootTaskDailyTaskCountRequested({required this.date});

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

final class RootTaskTabFocusNoteTypeChanged extends RootTaskEvent {
  const RootTaskTabFocusNoteTypeChanged({required this.tab, this.noteType});

  final RootTaskTab tab;
  final NoteType? noteType;

  @override
  List<Object?> get props => [tab, noteType];
}

final class RootTaskRefreshRequested extends RootTaskEvent {
  const RootTaskRefreshRequested();
}
