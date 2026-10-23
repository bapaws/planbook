import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/model/app_seed_colors.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/cubit/note_type_new_cubit.dart';
import 'package:flutter_planbook/note/type/view/note_new_type_textfield.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/root/task/view/root_task_page.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/month/bloc/task_month_bloc.dart';
import 'package:flutter_planbook/task/month/view/task_month_calendar_view.dart';
import 'package:flutter_planbook/task/month/view/task_month_cell.dart';
import 'package:flutter_planbook/task/month/view/task_month_page.dart';
import 'package:flutter_planbook/task/service/task_action_service.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:flutter_planbook/task/today/view/task_focus_view.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:flutter_planbook/task/week/model/task_week_view_mode.dart';
import 'package:flutter_planbook/task/week/view/task_week_calendar_view.dart';
import 'package:flutter_planbook/task/week/view/task_week_cell.dart';
import 'package:flutter_planbook/task/week/view/task_week_focus_cell.dart';
import 'package:flutter_planbook/task/week/view/task_week_list_day_group.dart';
import 'package:flutter_planbook/task/week/view/task_week_list_day_tasks.dart';
import 'package:flutter_planbook/task/week/view/task_week_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

class _Root extends MockBloc<RootTaskEvent, RootTaskState>
    implements RootTaskBloc {}

class _Week extends MockBloc<TaskWeekEvent, TaskWeekState>
    implements TaskWeekBloc {}

class _Month extends MockBloc<TaskMonthEvent, TaskMonthState>
    implements TaskMonthBloc {}

class _Today extends MockBloc<TaskTodayEvent, TaskTodayState>
    implements TaskTodayBloc {}

class _Home extends MockBloc<RootHomeEvent, RootHomeState>
    implements RootHomeBloc {}

class _App extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _Purchases extends MockBloc<AppPurchasesEvent, AppPurchasesState>
    implements AppPurchasesBloc {}

class _Tasks extends Mock implements TasksRepository {}

class _Tags extends Mock implements TagsRepository {}

class _Notes extends Mock implements NotesRepository {}

class _Actions extends Mock implements TaskActionService {}

final _date = Jiffy.parse('2026-10-19');

Note _note(String content, {NoteType? type}) {
  final resolved =
      type ??
      (content.startsWith('月')
          ? (content.contains('总结')
                ? NoteType.monthlySummary
                : NoteType.monthlyFocus)
          : (content.contains('总结')
                ? NoteType.weeklySummary
                : NoteType.weeklyFocus));
  return Note(
    id: content,
    title: content,
    content: content,
    images: const [],
    type: resolved,
    focusAt: PeriodNoteTarget(date: _date, type: resolved).focusAt,
    createdAt: _date,
  );
}

/// 用真实页面和任务列表 Bloc 验证局部重建，任务流只替换数据来源。
class _Harness {
  _Harness({TaskWeekViewMode weekMode = TaskWeekViewMode.grid}) {
    whenListen(
      root,
      rootStates.stream,
      initialState: RootTaskState(
        showSourcePanel: false,
        weekViewMode: weekMode,
      ),
    );
    when(() => root.isCompleted).thenAnswer((_) => root.state.isCompleted);
    whenListen(
      week,
      weekStates.stream,
      initialState: TaskWeekState(
        date: _date,
        focusNote: _note('周重点一'),
        isFocusNoteReady: true,
        isSummaryNoteReady: true,
      ),
    );
    whenListen(
      month,
      monthStates.stream,
      initialState: TaskMonthState(
        date: _date,
        weeks: _weeks(_date),
        focusNote: _note('月重点一'),
        isFocusNoteReady: true,
        isSummaryNoteReady: true,
      ),
    );
    whenListen(
      today,
      const Stream<TaskTodayState>.empty(),
      initialState: TaskTodayState(date: _date),
    );
    whenListen(
      purchases,
      const Stream<AppPurchasesState>.empty(),
      initialState: const AppPurchasesState(),
    );
    whenListen(
      home,
      const Stream<RootHomeState>.empty(),
      initialState: const RootHomeState(),
    );
    whenListen(
      app,
      const Stream<AppState>.empty(),
      initialState: const AppState(
        darkMode: DarkMode.light,
        seedColor: AppSeedColors.yellow,
      ),
    );
    when(
      () => tasks.getAllTodayTaskEntities(
        mode: any(named: 'mode'),
        day: any(named: 'day'),
        tagId: any(named: 'tagId'),
        priority: any(named: 'priority'),
        isCompleted: any(named: 'isCompleted'),
      ),
    ).thenAnswer((invocation) {
      final day = invocation.namedArguments[#day] as Jiffy?;
      if (day != null) {
        taskRequests++;
        final stream = taskStreamForDay?.call(day);
        if (stream != null) return stream;
      }
      return Stream.value(taskData);
    });
    when(
      () => notes.getNoteByFocusAt(any(), type: any(named: 'type')),
    ).thenAnswer(
      (call) => Stream.value(
        _note('路由笔记', type: call.namedArguments[#type] as NoteType?),
      ),
    );
  }

  final root = _Root();
  final week = _Week();
  final month = _Month();
  final today = _Today();
  final purchases = _Purchases();
  final home = _Home();
  final app = _App();
  final tasks = _Tasks();
  final notes = _Notes();
  final rootStates = StreamController<RootTaskState>.broadcast();
  final weekStates = StreamController<TaskWeekState>.broadcast();
  final monthStates = StreamController<TaskMonthState>.broadcast();
  int taskRequests = 0;
  List<TaskEntity> taskData = const [];
  Stream<List<TaskEntity>> Function(Jiffy day)? taskStreamForDay;

  Widget wrap(Widget child, {RootStackRouter? router}) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TasksRepository>.value(value: tasks),
        RepositoryProvider<TagsRepository>.value(value: _Tags()),
        RepositoryProvider<NotesRepository>.value(value: notes),
        RepositoryProvider<TaskActionService>.value(value: _Actions()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RootTaskBloc>.value(value: root),
          BlocProvider<TaskWeekBloc>.value(value: week),
          BlocProvider<TaskMonthBloc>.value(value: month),
          BlocProvider<TaskTodayBloc>.value(value: today),
          BlocProvider<AppPurchasesBloc>.value(value: purchases),
          BlocProvider<RootHomeBloc>.value(value: home),
          BlocProvider<AppBloc>.value(value: app),
        ],
        child: router == null
            ? MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: EasyLoading.init(),
                home: Scaffold(body: child),
              )
            : MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router.config(),
              ),
      ),
    );
  }

  Future<void> close() async {
    await rootStates.close();
    await weekStates.close();
    await monthStates.close();
  }
}

List<List<Jiffy?>> _weeks(Jiffy date) {
  final days = List<Jiffy?>.generate(
    date.daysInMonth,
    (i) => date.startOf(Unit.month).add(days: i),
  );
  final offset = date.startOf(Unit.month).dateTime.weekday - 1;
  days.insertAll(0, List<Jiffy?>.filled(offset, null));
  while (days.length % 7 != 0) {
    days.add(null);
  }
  return [
    for (var i = 0; i < days.length; i += 7) days.sublist(i, i + 7),
  ];
}

List<TaskListBloc> _taskBlocs(WidgetTester tester) {
  return tester.allElements
      .where(
        (element) =>
            element.widget is TaskMonthCell ||
            element.widget is TaskWeekCell ||
            element.widget is TaskWeekListDayTasksSliver,
      )
      .map((element) => element.read<TaskListBloc>())
      .toList();
}

TaskEntity _task(String id, {bool tagged = false}) => TaskEntity(
  task: Task(
    id: id,
    title: id,
    layer: 0,
    childCount: 0,
    order: 0,
    isAllDay: true,
    alarms: const [],
    createdAt: _date,
  ),
  tags: [
    if (tagged)
      TagEntity(
        tag: Tag(
          id: 'work',
          name: '工作',
          order: 0,
          level: 0,
          createdAt: _date,
        ),
      ),
  ],
);

class _DayFeed {
  _DayFeed(this.day);

  final Jiffy day;
  bool cancelled = false;
  late final controller = StreamController<List<TaskEntity>>(
    onCancel: () => cancelled = true,
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  // 抽屉等组件包含循环动画，只推进数据交付和本轮切换动画的有限帧。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_date);
    registerFallbackValue(TaskListMode.today);
    registerFallbackValue(TaskPriority.high);
    registerFallbackValue(NoteType.weeklyFocus);
    registerFallbackValue(
      PeriodNoteTarget(date: _date, type: NoteType.monthlyFocus),
    );
  });

  for (final mode in TaskWeekViewMode.values) {
    testWidgets('周$mode：重点总结独立更新，保留任务网格和订阅；切周仍更新日期', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = _Harness(weekMode: mode);
      addTearDown(h.close);
      await tester.pumpWidget(h.wrap(const TaskWeekPage()));
      await _settle(tester);
      final cells = mode == TaskWeekViewMode.grid
          ? find.byType(TaskWeekCell)
          : find.byType(TaskWeekListDayGroup);
      expect(cells, findsWidgets);
      final before = tester.widgetList(cells).toList();
      final requests = h.taskRequests;
      h.weekStates.add(h.week.state.copyWith(focusNote: () => _note('周重点二')));
      await _settle(tester);
      expect(find.text('周重点二'), findsOneWidget);
      expect(tester.widgetList(cells).toList(), orderedEquals(before));
      expect(h.taskRequests, requests);
      h.weekStates.add(
        h.week.state.copyWith(summaryNote: () => _note('周总结一')),
      );
      await _settle(tester);
      expect(find.text('周重点二'), findsOneWidget);
      h.rootStates.add(
        h.root.state.copyWith(
          tabFocusNoteTypes: const {RootTaskTab.week: NoteType.weeklySummary},
        ),
      );
      await _settle(tester);
      expect(find.text('周总结一'), findsOneWidget);
      h.weekStates.add(h.week.state.copyWith(isCalendarExpanded: true));
      await _settle(tester);
      expect(find.byType(TaskWeekCalendarView), findsOneWidget);
      expect(h.taskRequests, requests);
      h.weekStates.add(h.week.state.copyWith(date: _date.add(weeks: 1)));
      await _settle(tester);
      final days = mode == TaskWeekViewMode.grid
          ? tester.widgetList<TaskWeekCell>(cells).map((cell) => cell.day!)
          : tester
                .widgetList<TaskWeekListDayGroup>(cells)
                .map((cell) => cell.day);
      expect(
        days.every(
          (day) => !day.isBefore(_date.add(weeks: 1).startOf(Unit.week)),
        ),
        isTrue,
      );
      expect(h.taskRequests, greaterThan(requests));
      // 标题和实际持有的查询日期必须同步，防止只更新日期头却保留旧周订阅。
      expect(
        _taskBlocs(tester).every(
          (bloc) =>
              bloc.state.date!.isSame(_date.add(weeks: 1), unit: Unit.week),
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('月视图：笔记独立更新且可隐藏，日期网格保留，切月和日历仍更新', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = _Harness();
    addTearDown(h.close);
    await tester.pumpWidget(h.wrap(const TaskMonthPage()));
    await _settle(tester);
    final cells = find.byType(TaskMonthCell);
    expect(cells, findsNWidgets(31));
    final before = tester.widgetList(cells).toList();
    final requests = h.taskRequests;
    h.monthStates.add(h.month.state.copyWith(focusNote: () => _note('月重点二')));
    await _settle(tester);
    expect(find.text('月重点二'), findsOneWidget);
    expect(tester.widgetList(cells).toList(), orderedEquals(before));
    expect(h.taskRequests, requests);
    h.monthStates.add(h.month.state.copyWith(summaryNote: () => _note('月总结一')));
    await _settle(tester);
    h.rootStates.add(
      h.root.state.copyWith(
        tabFocusNoteTypes: const {RootTaskTab.month: NoteType.monthlySummary},
      ),
    );
    await _settle(tester);
    expect(find.text('月总结一'), findsOneWidget);
    h.rootStates.add(h.root.state.copyWith(tabFocusNoteTypes: const {}));
    await _settle(tester);
    expect(find.byType(TaskFocusView), findsNothing);
    h.monthStates.add(h.month.state.copyWith(summaryNote: () => _note('月总结二')));
    await _settle(tester);
    h.rootStates.add(
      h.root.state.copyWith(
        tabFocusNoteTypes: const {RootTaskTab.month: NoteType.monthlySummary},
      ),
    );
    await _settle(tester);
    expect(find.text('月总结二'), findsOneWidget);
    h.monthStates.add(h.month.state.copyWith(isCalendarExpanded: true));
    await _settle(tester);
    expect(find.byType(TaskMonthCalendarView), findsOneWidget);
    expect(h.taskRequests, requests);
    final next = _date.add(months: 1);
    h.monthStates.add(h.month.state.copyWith(date: next, weeks: _weeks(next)));
    await _settle(tester);
    expect(cells, findsNWidgets(30));
    expect(
      tester
          .widgetList<TaskMonthCell>(cells)
          .every((cell) => cell.day.month == 11),
      isTrue,
    );
    expect(h.taskRequests, greaterThan(requests));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final layout in ['week_grid', 'week_list', 'month']) {
    testWidgets('$layout：局部重建后标签与完成筛选仍走原任务订阅', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = _Harness(
        weekMode: layout == 'week_list'
            ? TaskWeekViewMode.list
            : TaskWeekViewMode.grid,
      )..taskData = [_task('tagged', tagged: true), _task('plain')];
      addTearDown(h.close);
      await tester.pumpWidget(
        h.wrap(
          layout == 'month' ? const TaskMonthPage() : const TaskWeekPage(),
        ),
      );
      await _settle(tester);
      final blocs = _taskBlocs(tester);
      expect(blocs, isNotEmpty);
      expect(blocs.every((bloc) => bloc.state.tasks.length == 2), isTrue);
      final requests = h.taskRequests;
      h.rootStates.add(h.root.state.copyWith(selectedTagIds: {'work'}));
      await _settle(tester);
      expect(_taskBlocs(tester), orderedEquals(blocs));
      expect(
        blocs.every(
          (bloc) => bloc.state.tasks.map((task) => task.id).join() == 'tagged',
        ),
        isTrue,
      );
      expect(h.taskRequests, greaterThan(requests));
      h.rootStates.add(h.root.state.copyWith(showCompleted: false));
      await _settle(tester);
      expect(blocs.every((bloc) => bloc.state.isCompleted == false), isTrue);
      h.rootStates.add(h.root.state.copyWith(selectedTagIds: {}));
      await _settle(tester);
      expect(blocs.every((bloc) => bloc.state.tasks.length == 2), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final layout in ['week_grid', 'week_list', 'month']) {
    testWidgets('$layout：快速切日期后旧流迟到不会覆盖新日期，返回时重新加载', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = _Harness(
        weekMode: layout == 'week_list'
            ? TaskWeekViewMode.list
            : TaskWeekViewMode.grid,
      );
      final feeds = <_DayFeed>[];
      h.taskStreamForDay = (day) {
        final feed = _DayFeed(day);
        feeds.add(feed);
        return feed.controller.stream;
      };
      addTearDown(h.close);
      addTearDown(() async {
        for (final feed in feeds) {
          await feed.controller.close();
        }
      });
      await tester.pumpWidget(
        h.wrap(
          layout == 'month' ? const TaskMonthPage() : const TaskWeekPage(),
        ),
      );
      await _settle(tester);
      final oldBlocs = _taskBlocs(tester);
      final firstFeeds = feeds.toList();
      void select(Jiffy date) {
        if (layout == 'month') {
          h.monthStates.add(
            h.month.state.copyWith(date: date, weeks: _weeks(date)),
          );
        } else {
          h.weekStates.add(h.week.state.copyWith(date: date));
        }
      }

      select(layout == 'month' ? _date.add(months: 1) : _date.add(weeks: 1));
      await _settle(tester);
      final secondFeeds = feeds.where((feed) => !feed.cancelled).toList();
      select(layout == 'month' ? _date.add(months: 2) : _date.add(weeks: 2));
      await _settle(tester);
      await tester.runAsync(pumpEventQueue);
      expect(
        oldBlocs.every((bloc) => bloc.isClosed),
        isTrue,
        reason:
            '旧 Bloc: ${oldBlocs.map((b) => (b.state.date, b.isClosed))}; '
            '当前: ${_taskBlocs(tester).map((b) => b.state.date)}; '
            '流: ${feeds.map((f) => (f.day, f.cancelled))}',
      );
      expect(
        [...firstFeeds, ...secondFeeds].every((feed) => feed.cancelled),
        isTrue,
      );
      final currentBlocs = _taskBlocs(tester);
      for (final feed in feeds.where((feed) => !feed.cancelled)) {
        feed.controller.add([_task('current_${feed.day.dateKey}')]);
      }
      // 模拟旧查询已在执行、页面切换后才返回结果。
      for (final feed in [...firstFeeds, ...secondFeeds]) {
        feed.controller.add([_task('late_old')]);
      }
      await _settle(tester);
      for (final bloc in currentBlocs) {
        expect(
          bloc.state.tasks.single.id,
          'current_${bloc.state.date!.dateKey}',
        );
      }
      select(_date);
      await _settle(tester);
      await tester.runAsync(pumpEventQueue);
      expect(currentBlocs.every((bloc) => bloc.isClosed), isTrue);
      for (final feed in feeds.where((feed) => !feed.cancelled)) {
        feed.controller.add([_task('return_${feed.day.dateKey}')]);
      }
      await _settle(tester);
      for (final bloc in _taskBlocs(tester)) {
        expect(
          bloc.state.tasks.single.id,
          'return_${bloc.state.date!.dateKey}',
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final mode in TaskWeekViewMode.values) {
    testWidgets('周$mode：同周重新选日保留任务 Bloc，清空笔记与切总结立即生效', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = _Harness(weekMode: mode);
      addTearDown(h.close);
      await tester.pumpWidget(h.wrap(const TaskWeekPage()));
      await _settle(tester);
      final before = _taskBlocs(tester);
      final requests = h.taskRequests;
      h.weekStates.add(h.week.state.copyWith(date: _date.add(days: 1)));
      await _settle(tester);
      expect(_taskBlocs(tester), orderedEquals(before));
      expect(h.taskRequests, requests);
      h.weekStates.add(h.week.state.copyWith(focusNote: () => null));
      await _settle(tester);
      expect(find.text('周重点一'), findsNothing);
      h.weekStates.add(h.week.state.copyWith(summaryNote: () => _note('最新总结')));
      await _settle(tester);
      h.rootStates.add(
        h.root.state.copyWith(
          tabFocusNoteTypes: const {RootTaskTab.week: NoteType.weeklySummary},
        ),
      );
      await _settle(tester);
      expect(find.text('最新总结'), findsOneWidget);
      if (mode == TaskWeekViewMode.grid) {
        expect(
          tester.widget<TaskWeekFocusCell>(find.byType(TaskWeekFocusCell)).note,
          _note('最新总结'),
        );
      } else {
        expect(
          tester.widget<TaskFocusView>(find.byType(TaskFocusView)).note,
          _note('最新总结'),
        );
      }
      expect(h.taskRequests, requests);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final layout in ['week_grid', 'week_list', 'month']) {
    testWidgets('$layout：未就绪卡片不接收拖入，旧回调不打开错误周期，空笔记使用所选日期', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = _Harness(
        weekMode: layout == 'week_list'
            ? TaskWeekViewMode.list
            : TaskWeekViewMode.grid,
      );
      addTearDown(h.close);
      final opened = <NoteNewTypeRouteArgs>[];
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'SafetyRoot',
            path: '/',
            builder: (_, _) => Scaffold(
              body: layout == 'month'
                  ? const TaskMonthPage()
                  : const TaskWeekPage(),
            ),
          ),
          NamedRouteDef(
            name: NoteNewTypeRoute.name,
            builder: (_, data) {
              opened.add(data.argsAs<NoteNewTypeRouteArgs>());
              return const SizedBox();
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(h.wrap(const SizedBox(), router: router));
      await _settle(tester);
      final card = find.byType(
        layout == 'week_grid' ? TaskWeekFocusCell : TaskFocusView,
      );
      VoidCallback callback() => layout == 'week_grid'
          ? tester.widget<TaskWeekFocusCell>(card).onTap!
          : tester.widget<TaskFocusView>(card).onTap;
      final oldTap = callback();
      final next = _date.add(months: 2);
      if (layout == 'month') {
        h.monthStates.add(
          h.month.state.copyWith(
            date: next,
            weeks: _weeks(next),
            focusNote: () => null,
            isFocusNoteReady: false,
            isSummaryNoteReady: false,
          ),
        );
      } else {
        h.weekStates.add(
          h.week.state.copyWith(
            date: next,
            focusNote: () => null,
            isFocusNoteReady: false,
            isSummaryNoteReady: false,
          ),
        );
      }
      await _settle(tester);
      final drag = tester.widget<TaskDragTarget>(
        find.descendant(of: card, matching: find.byType(TaskDragTarget)).first,
      );
      expect(drag.onAccept, isNull);
      oldTap();
      callback()();
      await _settle(tester);
      expect(opened, isEmpty);
      if (layout == 'month') {
        h.monthStates.add(h.month.state.copyWith(isFocusNoteReady: true));
      } else {
        h.weekStates.add(h.week.state.copyWith(isFocusNoteReady: true));
      }
      await _settle(tester);
      oldTap();
      await _settle(tester);
      expect(opened, isEmpty);
      callback()();
      await _settle(tester);
      expect(opened, hasLength(1));
      expect(opened.single.initialNote, isNull);
      final type = layout == 'month'
          ? NoteType.monthlyFocus
          : NoteType.weeklyFocus;
      expect(
        opened.single.focusAt,
        PeriodNoteTarget(date: next, type: type).focusAt,
      );
      await tester.pumpWidget(const SizedBox());
      oldTap();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('编辑器输入框等待当前笔记就绪后再显示和编辑，保存中禁止继续改动', (tester) async {
    final h = _Harness();
    addTearDown(h.close);
    final feed = StreamController<Note?>();
    final saved = Completer<Note>();
    when(() => h.notes.getNoteByFocusAt(any(), type: any(named: 'type')))
        .thenAnswer((_) => feed.stream);
    when(
      () => h.notes.savePeriodNote(
        target: any(named: 'target'),
        title: any(named: 'title'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) => saved.future);
    final cubit = NoteTypeNewCubit(
      notesRepository: h.notes,
      l10n: await AppLocalizations.delegate.load(const Locale('en')),
      focusAt: _date,
      type: NoteType.monthlyFocus,
    );
    addTearDown(() async {
      await cubit.close();
      await feed.close();
    });
    final loading = cubit.onRequested();
    await tester.pumpWidget(
      h.wrap(
        BlocProvider.value(value: cubit, child: const NoteNewTypeTextfield()),
      ),
    );
    await _settle(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    feed.add(_note('月重点一'));
    await loading;
    await _settle(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '月重点一',
    );
    await tester.enterText(find.byType(TextField), '本次编辑');
    final saving = cubit.onSave();
    await _settle(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(cubit.state.content, '本次编辑');
    saved.complete(_note('月重点一'));
    await saving;
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('周八宫格横竖屏布局有界、分隔线与单元格等高', (tester) async {
    final h = _Harness();
    addTearDown(h.close);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1200);
    await tester.pumpWidget(h.wrap(const TaskWeekPage()));
    await _settle(tester);
    expect(find.byType(TaskWeekCell), findsNWidgets(7));
    expect(find.byType(IntrinsicHeight), findsNothing);
    final heights = tester.widgetList<VerticalDivider>(
      find.byType(VerticalDivider),
    );
    expect(heights, hasLength(4));
    final cellHeight = tester.getSize(find.byType(TaskWeekCell).first).height;
    for (final divider in find.byType(VerticalDivider).evaluate()) {
      expect(tester.getSize(find.byWidget(divider.widget)).height, cellHeight);
    }
    tester.view.physicalSize = const Size(1200, 800);
    await _settle(tester);
    expect(find.byType(TaskWeekCell), findsNWidgets(7));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('真实任务页在天周月切换时保持 ScaffoldState，抽屉仍可打开', (tester) async {
    final h = _Harness();
    addTearDown(h.close);
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: RootTaskRoute.name,
          path: '/',
          builder: (_, _) => const RootTaskPage(),
          children: [
            for (final name in [
              TaskInboxRoute.name,
              TaskOverdueRoute.name,
              TaskTodayRoute.name,
              TaskWeekRoute.name,
              TaskMonthRoute.name,
            ])
              NamedRouteDef(
                name: name,
                initial: name == TaskTodayRoute.name,
                builder: (_, _) => Center(child: Text(name)),
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(h.wrap(const SizedBox(), router: router));
    await _settle(tester);
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    final tabs = AutoTabsRouter.of(
      tester.element(find.text(TaskTodayRoute.name)),
    );
    for (final tab in [RootTaskTab.week, RootTaskTab.month, RootTaskTab.day]) {
      tabs.setActiveIndex(tab.index);
      await _settle(tester);
      expect(
        tester.state<ScaffoldState>(find.byType(Scaffold)),
        same(scaffold),
      );
    }
    await tester.tap(find.byType(CupertinoButton).first);
    await _settle(tester);
    expect(scaffold.isDrawerOpen, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
