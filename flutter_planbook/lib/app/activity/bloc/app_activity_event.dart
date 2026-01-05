part of 'app_activity_bloc.dart';

sealed class AppActivityEvent extends Equatable {
  const AppActivityEvent();

  @override
  List<Object> get props => [];
}

final class AppActivityRequested extends AppActivityEvent {
  const AppActivityRequested();
}

final class AppActivityFetched extends AppActivityEvent {
  const AppActivityFetched();
}

final class AppActivityNotShowAgain extends AppActivityEvent {
  const AppActivityNotShowAgain({required this.message});

  final ActivityMessageEntity message;
}

final class AppActivityWillShow extends AppActivityEvent {
  const AppActivityWillShow({required this.message, required this.date});

  final ActivityMessageEntity message;
  final DateTime date;
}
