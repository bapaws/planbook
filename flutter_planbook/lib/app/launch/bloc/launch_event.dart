part of 'launch_bloc.dart';

sealed class LaunchEvent extends Equatable {
  const LaunchEvent();

  @override
  List<Object> get props => [];
}

final class LaunchAuthStateChanged extends LaunchEvent {
  const LaunchAuthStateChanged();
}

final class LaunchAppLinks extends LaunchEvent {
  const LaunchAppLinks();
}

final class LaunchAnimationStatusChanged extends LaunchEvent {
  const LaunchAnimationStatusChanged({required this.status});

  final AnimationStatus status;

  @override
  List<Object> get props => [status];
}

final class LaunchAnimationFinished extends LaunchEvent {
  const LaunchAnimationFinished();
}
