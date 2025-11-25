part of 'root_home_bloc.dart';

sealed class RootHomeEvent extends Equatable {
  const RootHomeEvent();

  @override
  List<Object?> get props => [];
}

final class RootHomeRequested extends RootHomeEvent {
  const RootHomeRequested();
}

final class RootHomeTagSelected extends RootHomeEvent {
  const RootHomeTagSelected({required this.tagId});

  final String tagId;

  @override
  List<Object?> get props => [tagId];
}

final class RootHomeTagSelectedAll extends RootHomeEvent {
  const RootHomeTagSelectedAll();

  @override
  List<Object?> get props => [];
}

final class RootHomeTagUnselectedAll extends RootHomeEvent {
  const RootHomeTagUnselectedAll();

  @override
  List<Object?> get props => [];
}

final class RootHomeTagDeleted extends RootHomeEvent {
  const RootHomeTagDeleted({required this.tagId});

  final String tagId;

  @override
  List<Object?> get props => [tagId];
}

final class RootHomeTaskCountRequested extends RootHomeEvent {
  const RootHomeTaskCountRequested({required this.mode});

  final TaskListMode mode;

  @override
  List<Object?> get props => [mode];
}

final class RootHomeDayChanged extends RootHomeEvent {
  const RootHomeDayChanged({required this.day});

  final Jiffy day;

  @override
  List<Object?> get props => [day];
}
