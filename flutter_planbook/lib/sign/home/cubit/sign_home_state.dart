part of 'sign_home_cubit.dart';

enum SignHomeStatus {
  welcome,
  signInWithCode,
  signInWithPhone,
  signInWithEmail,
  signInWithPassword,
  signUp,
  forgotPassword,
}

final class SignHomeState extends Equatable {
  const SignHomeState({
    this.status = SignHomeStatus.welcome,
    this.isAgreedToTerms = false,
    this.authResponse,
  });

  final SignHomeStatus status;
  final bool isAgreedToTerms;
  final AuthResponse? authResponse;

  @override
  List<Object?> get props => [status, isAgreedToTerms, authResponse];

  SignHomeState copyWith({
    SignHomeStatus? status,
    bool? isAgreedToTerms,
    AuthResponse? authResponse,
  }) {
    return SignHomeState(
      status: status ?? this.status,
      isAgreedToTerms: isAgreedToTerms ?? this.isAgreedToTerms,
      authResponse: authResponse ?? this.authResponse,
    );
  }
}
