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
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final db = AppDatabase();
  final tagApi = DatabaseTagApi(db: db);
  final tagsRepository = TagsRepository(
    sp: sp,
    tagApi: tagApi,
  );
  final tasksRepository = TasksRepository(
    sp: sp,
    tagApi: tagApi,
    db: db,
  );
  final notesRepository = NotesRepository(
    sp: sp,
    db: db,
    tagApi: tagApi,
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

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: sp),
      RepositoryProvider.value(value: settingsRepository),
      RepositoryProvider.value(value: tagsRepository),
      RepositoryProvider.value(value: tasksRepository),
      RepositoryProvider.value(value: notesRepository),
      RepositoryProvider.value(value: assetsRepository),
      RepositoryProvider.value(value: UsersRepository.instance),
      RepositoryProvider(
        create: (context) => AppActivityRepository(
          appStoreRepository: AppStoreRepository(sp: sp),
          sp: sp,
        ),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (context) =>
              AppPurchasesBloc(
                  tasksRepository: context.read(),
                  notesRepository: context.read(),
                  tagsRepository: context.read(),
                  usersRepository: context.read(),
                )
                ..add(const AppPurchasesSubscriptionRequested())
                ..add(const AppPurchasesUserRequested())
                ..add(const AppPurchasesPackageRequested()),
        ),
        BlocProvider(
          create: (context) =>
              AppBloc(
                  settingsRepository: context.read(),
                  notesRepository: context.read(),
                  tagsRepository: context.read(),
                  tasksRepository: context.read(),
                  usersRepository: context.read(),
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
    //   configuration = AmazonConfiguration(<revenuecat_project_amazon_api_key>);
    // }
  } else if (Platform.isIOS) {
    configuration = PurchasesConfiguration('appl_aNYCwAWkYYxFFPdqMBTWIXzIzko')
      ..userDefaultsSuiteName = kAppGroupId;
  } else {
    throw UnimplementedError();
  }

  await Purchases.configure(configuration);
}
