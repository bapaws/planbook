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
    emit(state.copyWith(isPremium: isPremium));
  }

  Future<void> onAnimationFinished() async {
    emit(state.copyWith(status: PageStatus.success));
  }
}
