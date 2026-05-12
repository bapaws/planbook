import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:flutter_planbook/app/activity/repository/app_store_repository.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart' hide kAppGroupId;
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/view/app.dart';
import 'package:flutter_planbook/discover/cover/repository/discover_cover_repository.dart';
import 'package:flutter_planbook/task/service/task_action_service.dart';
import 'package:flutter_planbook/widget/widget_action_setup.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  await _initPurchases();
  await AppSupabase.initialize();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );

  runApp(await _initApp());
}

/// Inital the app
Future<Widget> _initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppHomeWidget.setAppGroupId(kAppGroupId);
  final sp = await SharedPreferences.getInstance();

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
    outboxApi: outboxApi,
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
        create: (context) => AppActivityRepository(
          appStoreRepository: AppStoreRepository(sp: sp),
          sp: sp,
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
        BlocProvider(
          create: (context) => AppActivityBloc(
            appActivityRepository: context.read(),
          )..add(const AppActivityFetched()),
        ),
      ],
      child: const App(),
    ),
  );
}

/// Initial the RevenueCat SDK
Future<void> _initPurchases() async {
  await Purchases.setProxyURL('https://api.rc-backup.com/');
  await Purchases.setLogLevel(LogLevel.error);

  /// Dvelopment use same id
  PurchasesConfiguration configuration;
  if (Platform.isAndroid) {
    configuration = PurchasesConfiguration('goog_jlxqPffDOplzoFISIizzxwRdFFk');
    // if (buildingForAmazon) {
    //   // use your preferred way to determine if this build is for Amazon store
    //   // checkout our MagicWeather sample for a suggestion
    //   configuration = AmazonConfiguration(
    //     <revenuecat_project_amazon_api_key>,
    //   );
    // }
  } else if (Platform.isIOS) {
    configuration = PurchasesConfiguration('appl_aNYCwAWkYYxFFPdqMBTWIXzIzko')
      ..userDefaultsSuiteName = kAppGroupId;
  } else {
    throw UnimplementedError();
  }

  await Purchases.configure(configuration);
}

Future<void> _migrationDatabasePath(SharedPreferences sp) async {
  final dbFile = await AppDatabase.getDatabaseFile();
  if (dbFile.existsSync()) {
    return;
  }
  unawaited(sp.remove(SupabaseNoteApi.kLastGetNotesTimestamp));
  unawaited(sp.remove(SupabaseTaskApi.kLastGetTasksTimestamp));
  unawaited(sp.remove(SupabaseTagApi.kLastGetTagsTimestamp));
}
