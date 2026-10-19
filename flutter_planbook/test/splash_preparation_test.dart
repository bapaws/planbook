import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/model/app_seed_colors.dart';
import 'package:flutter_planbook/app/splash/cubit/splash_cubit.dart';
import 'package:flutter_planbook/app/splash/view/splash_page.dart';
import 'package:flutter_planbook/app/startup/startup_preparation_coordinator.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

class _AppBloc extends Mock implements AppBloc {}

class _Purchases extends Mock implements AppPurchases {}

class _Tasks extends Mock implements TasksRepository {}

class _Users extends Mock implements UsersRepository {}

class _User extends Mock implements UserEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(Jiffy.now());
    final purchases = _Purchases();
    when(() => purchases.isPremium).thenAnswer((_) async => true);
    AppPurchases.instance = purchases;
  });

  for (final failsEarly in [false, true]) {
    testWidgets(
      '首帧后启动准备，动画独立结束，退出后安全收尾（提前失败：$failsEarly）',
      (tester) async {
        final tasks = _Tasks();
        final users = _Users();
        final user = _User();
        when(() => user.id).thenReturn('user');
        when(() => users.user).thenReturn(user);
        when(() => users.userProfile).thenReturn(null);
        final appBloc = _AppBloc();
        // 保留既有初始化门控，让测试停留在 Splash 检查动画结果。
        when(() => appBloc.state).thenReturn(
          const AppState(darkMode: null, seedColor: AppSeedColors.green),
        );
        when(() => appBloc.stream).thenAnswer((_) => const Stream.empty());
        final pending = Completer<void>();
        SchedulerPhase? phase;
        when(() => tasks.prepareForHome(date: any(named: 'date')))
            .thenAnswer((_) {
              phase = SchedulerBinding.instance.schedulerPhase;
              return pending.future;
            });
        final coordinator = StartupPreparationCoordinator(
          tasksRepository: tasks,
          usersRepository: users,
        );

        await tester.pumpWidget(
          RepositoryProvider.value(
            value: coordinator,
            child: RepositoryProvider<UsersRepository>.value(
              value: users,
              child: BlocProvider<AppBloc>.value(
                value: appBloc,
                child: const MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: SplashPage(),
                ),
              ),
            ),
          ),
        );
        expect(phase, SchedulerPhase.postFrameCallbacks);
        // 从页面子树读取实际 Cubit，预处理不应改变其状态门控。
        final splashCubit = tester
            .element(find.byType(Scaffold))
            .read<SplashCubit>();
        if (failsEarly) pending.completeError(StateError('准备失败'));
        await tester.pumpAndSettle();
        expect(splashCubit.state.status, PageStatus.success);
        expect(splashCubit.state.isPremium, isTrue);
        verify(() => tasks.prepareForHome(date: any(named: 'date'))).called(1);

        await tester.pumpWidget(const SizedBox.shrink());
        expect(splashCubit.isClosed, isTrue);
        if (!failsEarly) pending.complete();
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
