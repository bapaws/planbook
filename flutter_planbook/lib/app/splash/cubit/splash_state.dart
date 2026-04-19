part of 'splash_cubit.dart';

final class SplashState extends Equatable {
  const SplashState({
    this.status = PageStatus.initial,
    this.launchedCount = 0,
    this.isPremium = false,
    this.isLoggedIn = false,
  });

  final PageStatus status;
  final int launchedCount;
  final bool? isPremium;
  final bool isLoggedIn;

  @override
  List<Object?> get props => [status, launchedCount, isPremium, isLoggedIn];

  SplashState copyWith({
    PageStatus? status,
    int? launchedCount,
    bool? isPremium,
    bool? isLoggedIn,
  }) {
    return SplashState(
      status: status ?? this.status,
      launchedCount: launchedCount ?? this.launchedCount,
      isPremium: isPremium ?? this.isPremium,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}
