part of 'launch_bloc.dart';

class LaunchState extends Equatable {
  const LaunchState({
    this.appLinksUri,
    this.animationStatus = AnimationStatus.dismissed,
    this.isAnimationFinished = false,
  });

  final Uri? appLinksUri;

  final AnimationStatus animationStatus;
  final bool isAnimationFinished;

  @override
  List<Object?> get props => [
    appLinksUri,
    animationStatus,
    isAnimationFinished,
  ];

  LaunchState copyWith({
    Uri? appLinksUri,
    bool? isAnimationFinished,
    AnimationStatus? animationStatus,
  }) {
    return LaunchState(
      appLinksUri: appLinksUri ?? this.appLinksUri,
      isAnimationFinished: isAnimationFinished ?? this.isAnimationFinished,
      animationStatus: animationStatus ?? this.animationStatus,
    );
  }
}
