part of 'sign_password_cubit.dart';

sealed class SignPasswordState extends Equatable {
  const SignPasswordState();

  @override
  List<Object> get props => [];
}

final class SignPasswordInitial extends SignPasswordState {}

final class SignPasswordLoading extends SignPasswordState {}

final class SignPasswordSuccess extends SignPasswordState {}

final class SignPasswordFailure extends SignPasswordState {
  const SignPasswordFailure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
