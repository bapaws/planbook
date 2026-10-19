import 'dart:async';

/// 合并整个拉取与落库过程；进行中的普通拉取不能吞掉后到的强制请求。
class PullSyncCoordinator {
  final _requests = <String?, ({bool force, Future<void> future})>{};
  final _successfulAt = <String?, DateTime>{};

  Future<void> run({
    required String? userId,
    required bool force,
    required Future<void> Function({required bool force}) action,
  }) {
    final existing = _requests[userId];
    if (existing != null && (!force || existing.force)) return existing.future;
    if (existing == null && !force) {
      final successfulAt = _successfulAt[userId];
      if (successfulAt != null &&
          DateTime.now().difference(successfulAt) <
              const Duration(seconds: 3)) {
        return Future.value();
      }
    }
    late final Future<void> request;
    request =
        Future<void>(() async {
          if (existing != null) {
            try {
              await existing.future;
            } on Object {
              // 原请求仍向其调用者报错，强制重试独立执行。
            }
          }
          await action(force: force);
          _successfulAt[userId] = DateTime.now();
        }).whenComplete(() {
          if (identical(_requests[userId]?.future, request)) {
            _requests.remove(userId);
          }
        });
    _requests[userId] = (force: force, future: request);
    return request;
  }
}
