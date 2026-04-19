import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/splash/cubit/splash_cubit.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:planbook_core/data/page_status.dart';

@RoutePage()
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SplashCubit(usersRepository: context.read())..onLaunched(),
      child: const _SplashPageView(),
    );
  }
}

class _SplashPageView extends StatefulWidget {
  const _SplashPageView();

  @override
  State<_SplashPageView> createState() => _SplashPageViewState();
}

class _SplashPageViewState extends State<_SplashPageView> {
  bool _shouldNavigate = false;
  SplashState? _pendingNavigationState;

  void _handleNavigation({SplashState? state}) {
    final splashState = state ?? context.read<SplashCubit>().state;
    final isPremium = splashState.isPremium;
    if (isPremium == null) return;

    final isLoggedIn = splashState.isLoggedIn;
    if (!isLoggedIn) {
      context.router.replace(const SignHomeRoute());
      return;
    }

    final launchedCount = splashState.launchedCount;
    if (!isPremium && _shouldShowPaywall(launchedCount)) {
      context.router.replaceAll([
        const RootHomeRoute(),
        const AppPurchasesRoute(),
      ]);
    } else {
      context.router.replace(const RootHomeRoute());
    }
  }

  void _onSplashStateChanged(BuildContext context, SplashState state) {
    if (state.status != PageStatus.success || state.isPremium == null) return;

    final appBloc = context.read<AppBloc>();
    if (appBloc.state.isInitialized) {
      _handleNavigation(state: state);
    } else {
      _shouldNavigate = true;
      _pendingNavigationState = state;
    }
  }

  void _onAppStateChanged(BuildContext context, AppState state) {
    if (!state.isInitialized) return;

    if (_shouldNavigate) {
      _handleNavigation(state: _pendingNavigationState);
      _shouldNavigate = false;
      _pendingNavigationState = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      listenWhen: (p, c) => !p.isInitialized && c.isInitialized,
      listener: _onAppStateChanged,
      child: BlocListener<SplashCubit, SplashState>(
        listenWhen: (p, c) =>
            p.status != c.status && c.status == PageStatus.success,
        listener: _onSplashStateChanged,
        child: const _ThemedSplashContent(),
      ),
    );
  }

  static bool _shouldShowPaywall(int launchedCount) {
    const firstPaywallLaunch = 5;
    const intervals = <int>[5, 6, 8, 10];
    const steadyStateInterval = 12;

    if (launchedCount < firstPaywallLaunch) return false;

    var trigger = firstPaywallLaunch;
    if (launchedCount == trigger) return true;

    for (final interval in intervals) {
      trigger += interval;
      if (launchedCount == trigger) return true;
      if (launchedCount < trigger) return false;
    }

    return (launchedCount - trigger) % steadyStateInterval == 0;
  }
}

class _ThemedSplashContent extends StatelessWidget {
  const _ThemedSplashContent();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppBloc>().state;
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    // AppBloc 未初始化时，使用系统亮度创建临时主题
    // 始终包裹 Theme，避免 initialized 变化时 widget 树结构改变
    final themeData = appState.isInitialized
        ? Theme.of(context)
        : ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: appState.seedColor.color,
              brightness: brightness,
            ),
          );

    return Theme(
      data: themeData,
      child: const _SplashContent(),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      body: Column(
        children: [
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Logo(colorScheme: colorScheme),
              const SizedBox(width: 8),
              _Title(colorScheme: colorScheme),
            ],
          ),
          const SizedBox(height: kToolbarHeight),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadows: [
              BoxShadow(
                color: colorScheme.surfaceContainerHighest,
                blurRadius: 4,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            width: kMinInteractiveDimension,
            height: kMinInteractiveDimension,
          ),
        )
        .animate(
          onComplete: (_) => context.read<SplashCubit>().onAnimationFinished(),
        )
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appName,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.slogen,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.1, end: 0, duration: 500.ms);
  }
}
