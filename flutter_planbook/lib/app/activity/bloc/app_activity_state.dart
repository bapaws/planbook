part of 'app_activity_bloc.dart';

final class AppActivityState extends Equatable {
  const AppActivityState({
    this.activities = const [],
    this.isReleasedVersion = false,
  });

  final List<ActivityMessageEntity> activities;
  final bool isReleasedVersion;

  @override
  List<Object> get props => [activities, isReleasedVersion];

  AppActivityState copyWith({
    List<ActivityMessageEntity>? activities,
    bool? isReleasedVersion,
  }) {
    return AppActivityState(
      activities: activities ?? this.activities,
      isReleasedVersion: isReleasedVersion ?? this.isReleasedVersion,
    );
  }
}
