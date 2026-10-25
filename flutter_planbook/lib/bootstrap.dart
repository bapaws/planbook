import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart' hide kAppGroupId;
import 'package:flutter_planbook/app/privacy/view/privacy_consent_page.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/startup/startup_preparation_coordinator.dart';
import 'package:flutter_planbook/app/view/app.dart';
import 'package:flutter_planbook/core/model/app_channel.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:flutter_planbook/discover/cover/repository/discover_cover_repository.dart';
import 'package:flutter_planbook/discover/diary/bloc/diary_notebook_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/service/task_action_service.dart';
import 'package:flutter_planbook/widget/widget_action_setup.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planbook_api/database/database_recovery.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/supabase_planbook_api.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log(error.toString(), stackTrace: stack);
    return true;
  };

  Bloc.observer = const AppBlocObserver();

  runApp(const _BootstrapApp());
}

/// 启动门控：国内渠道需先同意隐私政策，再初始化 SDK 并挂载主 App
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  Widget? _app;
  bool _needsConsent = false;
  bool _databaseUnavailable = false;
  late SharedPreferences _sp;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    _sp = await SharedPreferences.getInstance();

    if (Platform.isAndroid && AppChannel.isAndroidChina) {
      final accepted = SettingsRepository.getPrivacyConsentAcceptedFrom(_sp);
      if (!accepted) {
        setState(() => _needsConsent = true);
        return;
      }
    }

    await _completeBootstrap();
  }

  Future<void> _onConsentAccepted() async {
    await SettingsRepository.savePrivacyConsentAcceptedTo(
      _sp,
      accepted: true,
    );
    setState(() => _needsConsent = false);
    await _completeBootstrap();
  }

  Future<void> _completeBootstrap() async {
    if (mounted) setState(() => _databaseUnavailable = false);
    try {
      await AppPurchases.initialize(enableChinaPay: AppChannel.isAndroidChina);
      await AppSupabase.initialize();

      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: kIsWeb
            ? HydratedStorageDirectory.web
            : HydratedStorageDirectory((await getTemporaryDirectory()).path),
      );

      final app = await _initApp();
      if (mounted) {
        setState(() => _app = app);
      }
    } on DatabaseRecoveryException {
      // 数据库仍被占用或检查失败时停在可重试页，不打开业务库。
      if (mounted) setState(() => _databaseUnavailable = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_app != null) {
      return _app!;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: _needsConsent
          ? PrivacyConsentPage(onAccepted: _onConsentAccepted)
          : _databaseUnavailable
          ? _StartupRecoveryPage(onRetry: _completeBootstrap)
          : const _BootstrapLoadingPage(),
    );
  }
}

/// 本地库暂时无法检查时停在这里，已有数据保持原样，用户可以重试。
class _StartupRecoveryPage extends StatelessWidget {
  const _StartupRecoveryPage({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.startupDatabaseUnavailable,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => unawaited(onRetry()),
                child: Text(l10n.startupDatabaseRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 启动初始化完成前的占位页，背景和 AppScaffold 保持一致（点状图片），
/// 避免在进入 SplashPage 前出现纯色闪烁。
class _BootstrapLoadingPage extends StatelessWidget {
  const _BootstrapLoadingPage();

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final backgroundAsset = isDark
        ? 'assets/images/bg_dot_tile_dark.png'
        : 'assets/images/bg_dot_tile_light.png';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        image: DecorationImage(
          image: AssetImage(backgroundAsset),
          scale: 3,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
      ),
    );
  }
}

/// Inital the app
Future<Widget> _initApp() async {
  await AppHomeWidget.setAppGroupId(kAppGroupId);
  final sp = await SharedPreferences.getInstance();

  // 检查成功后才能迁移路径并创建业务库；检查/保全失败必须保留异常、停止启动。
  await AppDatabase.recoverCorruptIfNeeded();

  /// Migration database path
  /// 当前情况是将数据库从 habits.sqlite 迁移到 planbook.sqlite
  /// 清除一些缓存数据，重新获取数据
  await _migrationDatabasePath(sp);

  final db = AppDatabase();
  final outboxApi = OutboxApi(db: db);
  final syncEngine = SyncEngine(
    outboxApi: outboxApi,
    supabase: AppSupabase.client,
  );
  final tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
  final tagsRepository = TagsRepository(
    db: db,
    sp: sp,
    tagApi: tagApi,
  );
  final tasksRepository = TasksRepository(
    sp: sp,
    tagApi: tagApi,
    db: db,
    outboxApi: outboxApi,
  );
  final notesRepository = NotesRepository(
    sp: sp,
    db: db,
    tagApi: tagApi,
    outboxApi: outboxApi,
  );
  final assetsRepository = AssetsRepository(
    supabase: AppSupabase.client,
    db: db,
  );

  AlarmNotificationService.instance.configure(
    loadTasks: tasksRepository.getTasksForAlarms,
    loadTask: tasksRepository.getTaskForAlarm,
    account: () => tasksRepository.userId,
  );

  await UsersRepository.initialize(
    db: db,
    sp: sp,
  );

  final settingsRepository = SettingsRepository(sp: sp);

  // 统一编排 Task 完成 / 删除 / 自动笔记 / 提醒 / 音效等副作用，
  // 由各 bloc / view / widget 入口共享同一份逻辑。
  final taskActionService = TaskActionService(
    tasksRepository: tasksRepository,
    notesRepository: notesRepository,
    settingsRepository: settingsRepository,
  );

  // 把小组件的 "完成任务" 事件接入到主 App 的 service，并通知 native 端 Flutter 已就绪。
  // 必须在 repos 全部创建完毕后调用，否则 native 端等到的 ready 信号不带可用 handler。
  unawaited(
    setupPlanbookWidgetActions(
      tasksRepository: tasksRepository,
      taskActionService: taskActionService,
    ),
  );

  syncEngine.start();

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: sp),
      RepositoryProvider.value(value: outboxApi),
      RepositoryProvider.value(value: syncEngine),
      RepositoryProvider.value(value: settingsRepository),
      RepositoryProvider.value(value: tagsRepository),
      RepositoryProvider.value(value: tasksRepository),
      RepositoryProvider.value(value: notesRepository),
      RepositoryProvider.value(value: assetsRepository),
      RepositoryProvider.value(value: taskActionService),
      RepositoryProvider.value(value: UsersRepository.instance),
      RepositoryProvider(
        create: (context) => StartupPreparationCoordinator(
          tasksRepository: tasksRepository,
          usersRepository: UsersRepository.instance,
        ),
      ),
      RepositoryProvider(
        create: (context) => DiscoverCoverRepository(
          supabase: AppSupabase.client,
          assetsRepository: assetsRepository,
        ),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              DiaryNotebookBloc(usersRepository: context.read()),
        ),
        BlocProvider(
          create: (context) =>
              AppPurchasesBloc(
                  tasksRepository: context.read(),
                  notesRepository: context.read(),
                  tagsRepository: context.read(),
                  usersRepository: context.read(),
                )
                ..add(const AppPurchasesRequested())
                ..add(const AppPurchasesUserRequested()),
        ),
        BlocProvider(
          create: (context) =>
              AppBloc(
                  settingsRepository: context.read(),
                  tagsRepository: context.read(),
                  tasksRepository: context.read(),
                  notesRepository: context.read(),
                  usersRepository: context.read(),
                  sp: context.read(),
                  syncEngine: context.read(),
                )
                ..add(const AppInitialized())
                ..add(const AppUserRequested()),
        ),
      ],
      child: const App(),
    ),
  );
}

Future<void> _migrationDatabasePath(SharedPreferences sp) async {
  final dbFile = await AppDatabase.getDatabaseFile();
  const generationKey = 'remote_database_generation_v1';
  if (dbFile.existsSync()) {
    if (!sp.containsKey(generationKey) &&
        !await sp.setString(
          generationKey,
          DateTime.now().microsecondsSinceEpoch.toString(),
        )) {
      throw StateError('业务库同步代次保存失败');
    }
    return;
  }
  if (!await sp.setString(
    generationKey,
    DateTime.now().microsecondsSinceEpoch.toString(),
  )) {
    throw StateError('业务库同步代次保存失败');
  }
  // 空业务库不能继承任何账号的旧游标，等待清理完成后再创建 Repository。
  for (final key in sp.getKeys()) {
    if (key.startsWith(SupabaseNoteApi.kLastGetNotesTimestamp) ||
        key.startsWith(SupabaseTaskApi.kLastGetTasksTimestamp) ||
        key.startsWith(SupabaseTagApi.kLastGetTagsTimestamp) ||
        key.startsWith('remote_row_versions_v1__') ||
        key.startsWith('occurrence_repair_v1__') ||
        key == 'startup_synced_account_v1') {
      await sp.remove(key);
    }
  }
}
