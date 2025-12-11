part of 'sign_home_cubit.dart';

enum SignHomeStatus {
  welcome,
  signInWithPhone,
  signInWithPassword,
  signUp,
  forgotPassword,
}

final class SignHomeState extends Equatable {
  const SignHomeState({
    this.status = SignHomeStatus.welcome,
    this.isAgreedToTerms = false,
  });

  final SignHomeStatus status;
  final bool isAgreedToTerms;

  @override
  List<Object> get props => [status, isAgreedToTerms];

  SignHomeState copyWith({
    SignHomeStatus? status,
    bool? isAgreedToTerms,
  }) {
    return SignHomeState(
      status: status ?? this.status,
      isAgreedToTerms: isAgreedToTerms ?? this.isAgreedToTerms,
    );
  }
}
