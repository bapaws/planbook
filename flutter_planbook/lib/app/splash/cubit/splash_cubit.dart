import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/users/users_repository.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit({
    required UsersRepository usersRepository,
  }) : _usersRepository = usersRepository,
       super(const SplashState());

  final UsersRepository _usersRepository;

  Future<void> onLaunched() async {
    final launchedCount = _usersRepository.userProfile?.launchCount ?? 0;
    if (isClosed) return;
    emit(
      state.copyWith(
        launchedCount: launchedCount + 1,
        isLoggedIn: _usersRepository.user != null,
      ),
    );

    unawaited(_onPremiumRequested());
  }

  Future<void> _onPremiumRequested() async {
    final isPremium = await AppPurchases.instance.isPremium;
    // 动画结束导航后 Cubit 可能已关闭，避免异步回调继续 emit
    if (isClosed) return;
    emit(state.copyWith(isPremium: isPremium));
  }

  Future<void> onAnimationFinished() async {
    if (isClosed) return;
    emit(state.copyWith(status: PageStatus.success));
  }
}
