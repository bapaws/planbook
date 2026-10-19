import 'dart:developer';

import 'package:planbook_repository/planbook_repository.dart';

/// 在 Splash 首帧后提前准备首页需要的本地数据，不参与路由门控。
class StartupPreparationCoordinator {
  StartupPreparationCoordinator({
    required this.tasksRepository,
    required this.usersRepository,
  });

  final TasksRepository tasksRepository;
  final UsersRepository usersRepository;
  final _requests = <(String, int, int, int), Future<void>>{};

  Future<void> prepareForHome({Jiffy? date}) {
    final user = usersRepository.user;
    if (user == null) return Future.value();

    final day = (date ?? Jiffy.now()).startOf(Unit.day);
    final key = (user.id, day.year, day.month, day.date);
    return _requests.putIfAbsent(
      key,
      () => _prepare(day).whenComplete(() {
        _requests.remove(key);
      }),
    );
  }

  Future<void> _prepare(Jiffy date) async {
    final stopwatch = Stopwatch()..start();
    try {
      // 只走本地实例缓存，不读取带隐含同步的首页 Stream，也不安排提醒。
      await tasksRepository.prepareForHome(date: date);
      log(
        '本地准备完成：${stopwatch.elapsedMilliseconds}ms',
        name: 'StartupPreparation',
      );
    } on Object catch (error, stackTrace) {
      // 预处理是可选加速；失败不阻止跳转，首页原有入口仍能重新生成。
      log(
        '本地准备失败，保留首页重试入口',
        name: 'StartupPreparation',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
