import 'dart:async';

import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/service/task_action_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

class _Settings extends Mock implements SettingsRepository {}

class _Tasks extends Mock implements TasksRepository {}

class _Tags extends Mock implements TagsRepository {}

class _Notes extends Mock implements NotesRepository {}

class _Users extends Mock implements UsersRepository {}

class _Sync extends Mock implements SyncEngine {}

class _Actions extends Mock implements TaskActionService {}

class _Storage extends Mock implements Storage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final date = Jiffy.parse('2026-10-17');

  test('同账号冷启动增量、资料更新不重拉；注销清空用户、换号仍全量', () async {
    SharedPreferences.setMockInitialValues({'startup_synced_account_v1': 'a'});
    final users = _Users();
    final tasks = _Tasks();
    final notes = _Notes();
    final tags = _Tags();
    final stream = StreamController<UserEntity?>();
    when(() => users.onUserEntityChange).thenAnswer((_) => stream.stream);
    when(tasks.rescheduleAllRecurringAlarms).thenAnswer((_) async {});
    when(() => tasks.syncTasks(force: any(named: 'force')))
        .thenAnswer((_) async {});
    when(() => notes.syncNotes(force: any(named: 'force')))
        .thenAnswer((_) async {});
    when(() => tags.syncTags(force: any(named: 'force')))
        .thenAnswer((_) async {});
    final bloc = AppBloc(
      settingsRepository: _Settings(),
      tagsRepository: tags,
      tasksRepository: tasks,
      notesRepository: notes,
      usersRepository: users,
      sp: await SharedPreferences.getInstance(),
      syncEngine: _Sync(),
    )..add(const AppUserRequested());
    UserEntity user(String id) => UserEntity(
      user: User(
        id: id,
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2026-10-18T00:00:00Z',
      ),
    );
    await pumpEventQueue();
    stream.add(user('a'));
    await pumpEventQueue();
    // 明确检查普通增量参数，避免冷启动重新落回全量。
    // ignore: avoid_redundant_argument_values
    verify(() => tasks.syncTasks(force: false)).called(1);
    verifyNever(() => tasks.syncTasks(force: true));
    stream.add(user('a'));
    await pumpEventQueue();
    verifyNever(() => tasks.syncTasks(force: any(named: 'force')));
    stream.add(null);
    await pumpEventQueue();
    expect(bloc.state.user, isNull);
    stream.add(user('b'));
    await pumpEventQueue();
    verify(() => tasks.syncTasks(force: true)).called(1);
    verify(() => notes.syncNotes(force: true)).called(1);
    verify(() => tags.syncTags(force: true)).called(1);
    await bloc.close();
    await stream.close();
  });

  test('并发与重复初始化只读取一次配置，设置监听仍可更新', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = _Settings();
    final lightScheme = Completer<Map<String, int>?>();
    var activeBackgroundListeners = 0;
    final backgrounds = StreamController<AppBackgroundEntity>(
      onListen: () => activeBackgroundListeners++,
      onCancel: () => activeBackgroundListeners--,
    );
    final quadrants = StreamController<List<QuadrantConfigEntity>>();
    when(settings.getDarkMode).thenReturn(DarkMode.light);
    when(settings.getLocale).thenReturn(null);
    when(settings.getSeedColorHex).thenReturn(null);
    when(settings.getLightColorScheme).thenAnswer((_) => lightScheme.future);
    when(settings.getDarkColorScheme).thenAnswer((_) async => {});
    when(() => settings.onBackgroundAssetChange)
        .thenAnswer((_) => backgrounds.stream);
    when(() => settings.onQuadrantConfigsChange)
        .thenAnswer((_) => quadrants.stream);
    final bloc =
        AppBloc(
            settingsRepository: settings,
            tagsRepository: _Tags(),
            tasksRepository: _Tasks(),
            notesRepository: _Notes(),
            usersRepository: _Users(),
            sp: await SharedPreferences.getInstance(),
            syncEngine: _Sync(),
          )
          ..add(const AppInitialized())
          ..add(const AppInitialized());
    await pumpEventQueue();
    verify(settings.getLightColorScheme).called(1);
    lightScheme.complete({});
    await bloc.stream.firstWhere((state) => state.isInitialized);
    await pumpEventQueue();
    bloc.add(const AppInitialized());
    await pumpEventQueue();
    verifyNever(settings.getLightColorScheme);
    expect(activeBackgroundListeners, 1);
    final background = AppBackgroundEntity.all.first;
    backgrounds.add(background);
    await pumpEventQueue();
    expect(bloc.state.background, background);
    await bloc.close();
    expect(activeBackgroundListeners, 0);
    await backgrounds.close();
    await quadrants.close();
  });

  for (final allDay in [false, true]) {
    test('任务流失败退出加载并保留数据，原订阅恢复后继续更新（全天：$allDay）', () async {
      final repository = _Tasks();
      final stream = StreamController<List<TaskEntity>>();
      when(
        () => repository.getTaskEntities(
          date: date,
          mode: TaskListMode.inbox,
        ),
      ).thenAnswer((_) => stream.stream);
      when(
        () => repository.getAllTodayTaskEntities(
          mode: TaskListMode.inbox,
          day: date,
        ),
      ).thenAnswer((_) => stream.stream);
      final bloc =
          TaskListBloc(
            tasksRepository: repository,
            taskActionService: _Actions(),
          )..add(
            allDay
                ? TaskListDayAllRequested(date: date)
                : TaskListRequested(date: date),
          );
      await pumpEventQueue();
      final task = TaskEntity(
        task: Task(
          id: 'task',
          title: '保留任务',
          layer: 0,
          childCount: 0,
          order: 0,
          isAllDay: false,
          alarms: const [],
          createdAt: date,
        ),
      );
      stream.add([task]);
      await pumpEventQueue();
      stream.addError(StateError('模拟数据库失败'));
      await pumpEventQueue();
      expect(bloc.state.status, PageStatus.failure);
      expect(bloc.state.tasks, [task]);
      stream.add([]);
      await pumpEventQueue();
      expect(bloc.state.status, PageStatus.success);
      expect(bloc.state.tasks, isEmpty);
      await bloc.close();
      await stream.close();
    });
  }

  test('同步抛出的任务查询异常也会结束 loading', () async {
    final repository = _Tasks();
    when(
      () => repository.getTaskEntities(
        date: date,
        mode: TaskListMode.inbox,
      ),
    ).thenThrow(StateError('查询创建失败'));
    final bloc = TaskListBloc(
      tasksRepository: repository,
      taskActionService: _Actions(),
    )..add(TaskListRequested(date: date));
    await pumpEventQueue();
    expect(bloc.state.status, PageStatus.failure);
    await bloc.close();
  });

  test('计数流异常保留已知计数，恢复后继续更新', () async {
    final storage = _Storage();
    when(() => storage.read(any<String>())).thenReturn(null);
    when(() => storage.write(any<String>(), any<dynamic>()))
        .thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    final repository = _Tasks();
    final counts = StreamController<int>();
    when(
      () => repository.getTaskCount(
        mode: TaskListMode.inbox,
        isCompleted: false,
      ),
    ).thenAnswer((_) => counts.stream);
    final bloc = RootTaskBloc(
      tasksRepository: repository,
      settingsRepository: _Settings(),
    )..add(const RootTaskTaskCountRequested(mode: TaskListMode.inbox));
    await pumpEventQueue();
    counts.add(7);
    await pumpEventQueue();
    counts.addError(StateError('计数失败'));
    await pumpEventQueue();
    expect(bloc.state.status, PageStatus.failure);
    expect(bloc.state.taskCounts[TaskListMode.inbox], 7);
    counts.add(8);
    await pumpEventQueue();
    expect(bloc.state.status, PageStatus.success);
    expect(bloc.state.taskCounts[TaskListMode.inbox], 8);
    await bloc.close();
    await counts.close();
  });
}
