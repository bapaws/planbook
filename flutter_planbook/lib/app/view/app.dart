import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:intl/intl.dart';
import 'package:planbook_core/planbook_core.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final _appRouter = AppRouter();
  late Brightness _brightness;
  late final methodChannel = const MethodChannel('com.bapaws.planbook.flutter');

  @override
  void initState() {
    final platformDispatcher = SchedulerBinding.instance.platformDispatcher
      ..onPlatformBrightnessChanged = _onPlatformBrightnessChanged;
    _brightness = platformDispatcher.platformBrightness;

    /// 这里的设置让 DateFormat 本地化生效
    Intl.defaultLocale = Intl.canonicalizedLocale(Platform.localeName);

    WidgetsBinding.instance.addObserver(this);
    _setupMethodChannelListener();

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPlatformBrightnessChanged() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    switch (brightness) {
      case Brightness.light:
        AppStyles.onPlatformBrightnessChanged(Brightness.light);
        setState(() {
          _brightness = Brightness.light;
        });
        // 延迟设置，确保 context 已更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _setupSystemNavigationBar();
        });
      case Brightness.dark:
        AppStyles.onPlatformBrightnessChanged(Brightness.dark);
        setState(() {
          _brightness = Brightness.dark;
        });
        // 延迟设置，确保 context 已更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _setupSystemNavigationBar();
        });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  /// 设置系统导航栏样式（保留用于平台亮度变化时的更新）
  void _setupSystemNavigationBar({AppState? state}) {
    if (!mounted) return;

    // 只在 Android 上设置 edgeToEdge 模式
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    }

    // 设置系统UI样式
    SystemChrome.setSystemUIOverlayStyle(
      _getSystemUiOverlayStyle(state ?? context.read<AppBloc>().state),
    );
  }

  SystemUiOverlayStyle _getSystemUiOverlayStyle(AppState state) {
    final currentTheme = state.getTheme(_brightness);
    final colorScheme = currentTheme.colorScheme;
    final themeBrightness = colorScheme.brightness;

    // 根据实际主题设置状态栏和导航栏图标颜色
    final iconBrightness = themeBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    return SystemUiOverlayStyle(
      // Android: 设置系统导航栏背景颜色
      systemNavigationBarColor: colorScheme.onSurface,
      systemNavigationBarIconBrightness: iconBrightness,
      statusBarColor: Colors.transparent,
      // Android 使用 statusBarIconBrightness
      statusBarIconBrightness: iconBrightness,
      // iOS 使用 statusBarBrightness（语义相反）
      statusBarBrightness: themeBrightness,
      systemNavigationBarContrastEnforced: false,
    );
  }

  Future<void> _setupMethodChannelListener() async {
    if (Platform.isIOS) {
      try {
        methodChannel.setMethodCallHandler((call) async {
          switch (call.method) {
            case 'completeTaskById':
              return true;
            case 'startFocusTimerByTaskId':
              return true;
            case 'stopFocusTimerByTaskId':
              return true;
            default:
              return null;
          }
        });
      } catch (e) {
        debugPrint('Failed to setup task completion listener: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _getSystemUiOverlayStyle(state),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: state.getTheme(_brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _appRouter.config(),
            builder: (context, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 只在 Android 上设置 edgeToEdge 模式
                if (Platform.isAndroid) {
                  SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.edgeToEdge,
                    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
                  );
                }
              });
              return EasyLoading.init()(context, child);
            },
          ),
        );
      },
    );
  }
}
