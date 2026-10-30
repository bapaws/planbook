import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show OrderingMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/model/app_seed_colors.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_flight.dart';
import 'package:flutter_planbook/discover/cover/repository/discover_cover_repository.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_repository/planbook_repository.dart';

class _Notes extends Mock implements NotesRepository {}

class _Tasks extends Mock implements TasksRepository {}

class _Users extends Mock implements UsersRepository {}

class _Settings extends Mock implements SettingsRepository {}

class _Covers extends Mock implements DiscoverCoverRepository {}

class _App extends MockBloc<AppEvent, AppState> implements AppBloc {}

/// 模拟主页的懒加载 Tab 与底部悬浮导航，首次切换才挂载真实发现页。
class _TabHost extends StatelessWidget {
  const _TabHost();

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    child: AutoTabsRouter(
      routes: const [PageRouteInfo('TaskPlaceholder'), RootDiscoverRoute()],
      transitionBuilder: (context, child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      builder: (context, child) => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          child,
          const Positioned(
            left: 24,
            right: 24,
            bottom: 22,
            child: RootHomeBottomBar(),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Jiffy.now());
    registerFallbackValue(OrderingMode.asc);
    registerFallbackValue(TaskListMode.today);
    registerFallbackValue(TaskPriority.none);
    registerFallbackValue(NoteListMode.journal);
    registerFallbackValue(NoteType.journal);
  });

  testWidgets('首次切入真实第二个 Tab 并反复开合计划本时语义树有效', (tester) async {
    final notes = _Notes();
    final tasks = _Tasks();
    final users = _Users();
    final settings = _Settings();
    final covers = _Covers();
    final app = _App();
    when(() => app.state).thenReturn(
      const AppState(darkMode: null, seedColor: AppSeedColors.green),
    );
    when(() => users.onUserProfileChange).thenAnswer((_) => Stream.value(null));
    when(settings.getDiscoverJournalFlipGestureHintShown).thenReturn(true);
    when(() => covers.imageProviderFor(any())).thenAnswer(
      (call) => AssetImage(call.positionalArguments.first as String),
    );
    when(
      () => tasks.getTaskCount(
        mode: any(named: 'mode'),
        date: any(named: 'date'),
        isCompleted: any(named: 'isCompleted'),
      ),
    ).thenAnswer((_) => Stream.value(0));
    when(
      () => tasks.getCompletedTaskCount(
        date: any(named: 'date'),
        priority: any(named: 'priority'),
      ),
    ).thenAnswer((_) => Stream.value(0));
    when(
      () => tasks.getCompletedTaskCountForMonth(
        any(),
        priority: any(named: 'priority'),
      ),
    ).thenAnswer((_) => Stream.value(0));
    when(() => tasks.getPlannedTaskCountForMonth(any()))
        .thenAnswer((_) => Stream.value(0));
    when(
      () => notes.getNoteEntitiesByDate(
        any(),
        mode: any(named: 'mode'),
        orderingMode: any(named: 'orderingMode'),
      ),
    ).thenAnswer((_) => Stream.value([]));
    when(() => notes.getNoteByFocusAt(any(), type: any(named: 'type')))
        .thenAnswer((_) => Stream.value(null));
    when(() => notes.getNoteEntitiesForMonth(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => notes.getNoteImageEntitiesForMonth(any()))
        .thenAnswer((_) => Stream.value([]));
    final root = RootDiscoverBloc();
    addTearDown(root.close);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo('Host', builder: (_) => const _TabHost()),
          initial: true,
          children: [
            AutoRoute(
              page: PageInfo(
                'TaskPlaceholder',
                builder: (_) => const SizedBox.expand(),
              ),
              initial: true,
            ),
            AutoRoute(
              page: RootDiscoverRoute.page,
              children: [
                AutoRoute(
                  initial: true,
                  page: DiscoverBrowseRoute.page,
                  children: [
                    AutoRoute(page: DiscoverJournalRoute.page, initial: true),
                    AutoRoute(page: DiscoverFocusRoute.page),
                    AutoRoute(page: DiscoverSummaryRoute.page),
                  ],
                ),
                CustomRoute<void>(
                  page: NotebookReaderRoute.page,
                  customRouteBuilder: notebookReaderFlightBuilder,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<NotesRepository>.value(value: notes),
          RepositoryProvider<UsersRepository>.value(value: users),
          RepositoryProvider<TasksRepository>.value(value: tasks),
          RepositoryProvider<SettingsRepository>.value(value: settings),
          RepositoryProvider<DiscoverCoverRepository>.value(value: covers),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: app),
            BlocProvider<RootDiscoverBloc>.value(value: root),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router.config(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getTopLeft(find.byType(RootHomeBottomBar)) +
          const Offset(
            kRootBottomBarItemWidth * 1.5,
            kRootBottomBarItemHeight / 2,
          ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Open'), findsOneWidget);
    for (var repeat = 0; repeat < 2; repeat++) {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
