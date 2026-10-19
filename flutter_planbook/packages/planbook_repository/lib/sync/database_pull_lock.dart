import 'package:planbook_api/planbook_api.dart';

/// 标签可同时由多个资源读取，串行化拉取到提交，避免旧快照后提交覆盖新版本。
/// 只串行化同步请求；业务查询和短写事务仍正常运行。
abstract final class DatabasePullLock {
  static final _tails = Expando<Future<void>>();

  static Future<void> run(AppDatabase db, Future<void> Function() action) {
    final previous = _tails[db] ?? Future<void>.value();
    final result = previous.then((_) => action());
    _tails[db] = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
