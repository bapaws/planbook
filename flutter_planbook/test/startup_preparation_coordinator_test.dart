import 'dart:async';

import 'package:flutter_planbook/app/startup/startup_preparation_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_repository/planbook_repository.dart';

class _Tasks extends Mock implements TasksRepository {}

class _Users extends Mock implements UsersRepository {}

class _User extends Mock implements UserEntity {}

void main() {
  final date = Jiffy.parse('2026-10-17');
  late _Tasks tasks;
  late _Users users;
  late StartupPreparationCoordinator coordinator;

  setUp(() {
    tasks = _Tasks();
    users = _Users();
    final user = _User();
    when(() => user.id).thenReturn('first-user');
    when(() => users.user).thenReturn(user);
    coordinator = StartupPreparationCoordinator(
      tasksRepository: tasks,
      usersRepository: users,
    );
  });

  test('未登录时不提前准备首页数据', () async {
    when(() => users.user).thenReturn(null);
    await coordinator.prepareForHome(date: date);
    verifyZeroInteractions(tasks);
  });

  test('同账号同一天只共享进行中的准备，完成后允许重新检查', () async {
    final pending = Completer<void>();
    when(() => tasks.prepareForHome(date: date)).thenAnswer(
      (_) => pending.future,
    );
    final first = coordinator.prepareForHome(date: date.add(hours: 1));
    final second = coordinator.prepareForHome(date: date.add(hours: 8));
    expect(identical(first, second), isTrue);
    verify(() => tasks.prepareForHome(date: date)).called(1);
    pending.complete();
    await first;

    await coordinator.prepareForHome(date: date);
    verify(() => tasks.prepareForHome(date: date)).called(1);
  });

  test('准备失败不向页面抛错，后续进入仍能重试', () async {
    when(() => tasks.prepareForHome(date: date)).thenThrow(
      StateError('本地查询暂时失败'),
    );
    await coordinator.prepareForHome(date: date);
    when(() => tasks.prepareForHome(date: date)).thenAnswer((_) async {});
    await coordinator.prepareForHome(date: date);
    verify(() => tasks.prepareForHome(date: date)).called(2);
  });

  test('跨日或切换账号不复用旧的准备请求', () async {
    final pending = Completer<void>();
    final tomorrow = date.add(days: 1);
    when(() => tasks.prepareForHome(date: date)).thenAnswer(
      (_) => pending.future,
    );
    when(() => tasks.prepareForHome(date: tomorrow)).thenAnswer((_) async {});
    final first = coordinator.prepareForHome(date: date);
    await coordinator.prepareForHome(date: tomorrow);
    final otherUser = _User();
    when(() => otherUser.id).thenReturn('second-user');
    when(() => users.user).thenReturn(otherUser);
    final other = coordinator.prepareForHome(date: date);
    expect(identical(first, other), isFalse);
    verify(() => tasks.prepareForHome(date: date)).called(2);
    verify(() => tasks.prepareForHome(date: tomorrow)).called(1);
    pending.complete();
    await Future.wait([first, other]);
  });
}
