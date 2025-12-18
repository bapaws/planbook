part of 'root_task_bloc.dart';

sealed class RootTaskEvent extends Equatable {
  const RootTaskEvent();

  @override
  List<Object?> get props => [];
}

final class RootTaskTabSelected extends RootTaskEvent {
  const RootTaskTabSelected({required this.tab});

  final TaskListMode tab;

  @override
  List<Object?> get props => [tab];
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
