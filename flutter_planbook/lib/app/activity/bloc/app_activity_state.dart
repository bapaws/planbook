part of 'app_activity_bloc.dart';

final class AppActivityState extends Equatable {
  const AppActivityState({
    this.activities = const [],
  });

  final List<ActivityMessageEntity> activities;

  @override
  List<Object> get props => [activities];

  AppActivityState copyWith({
    List<ActivityMessageEntity>? activities,
  }) {
    return AppActivityState(
      activities: activities ?? this.activities,
    );
  }
}
