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
    this.isWeChatLoading = false,
    this.isWeChatInstalled = false,
  });

  final SignHomeStatus status;
  final bool isAgreedToTerms;
  final AuthResponse? authResponse;
  final bool isWeChatLoading;
  final bool isWeChatInstalled;

  @override
  List<Object?> get props => [
    status,
    isAgreedToTerms,
    authResponse,
    isWeChatLoading,
    isWeChatInstalled,
  ];

  SignHomeState copyWith({
    SignHomeStatus? status,
    bool? isAgreedToTerms,
    AuthResponse? authResponse,
    bool? isWeChatLoading,
    bool? isWeChatInstalled,
  }) {
    return SignHomeState(
      status: status ?? this.status,
      isAgreedToTerms: isAgreedToTerms ?? this.isAgreedToTerms,
      authResponse: authResponse ?? this.authResponse,
      isWeChatLoading: isWeChatLoading ?? this.isWeChatLoading,
      isWeChatInstalled: isWeChatInstalled ?? this.isWeChatInstalled,
    );
  }
}
