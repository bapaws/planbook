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
      case Brightness.dark:
        AppStyles.onPlatformBrightnessChanged(Brightness.dark);
        setState(() {
          _brightness = Brightness.dark;
        });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  /// 设置系统导航栏样式
  void _setupSystemNavigationBar() {
    if (!Platform.isAndroid) return;
    if (!mounted) return;

    // 获取当前主题的背景颜色
    final currentTheme = context.read<AppBloc>().state.getTheme(_brightness);

    // 先设置系统UI模式，确保导航栏可见但不覆盖内容
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // 设置系统导航栏背景颜色与页面背景一致
        systemNavigationBarColor: currentTheme.colorScheme.surface,
        // 根据当前主题设置导航栏图标颜色
        systemNavigationBarIconBrightness: _brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        // 设置状态栏样式
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  Future<void> _setupMethodChannelListener() async {
    if (Platform.isIOS) {
      try {
        methodChannel.setMethodCallHandler((call) async {
          final arguments = Map<String, dynamic>.from(call.arguments as Map);
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
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: state.getTheme(_brightness),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _appRouter.config(),
          builder: (context, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _setupSystemNavigationBar();
            });
            return EasyLoading.init()(context, child);
          },
        );
      },
    );
  }
}
