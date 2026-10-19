import 'package:shared_preferences/shared_preferences.dart';

/// 首次登录、换号、注销后重登使用全量；同账号冷启动复用已提交的增量基线。
class StartupSyncPolicy {
  StartupSyncPolicy(this.sp);
  static const accountKey = 'startup_synced_account_v1';
  final SharedPreferences sp;
  bool _observed = false;
  String? _account;
  int _epoch = 0;

  Future<void> onAccount(
    String? account,
    Future<void> Function({required bool force}) synchronize,
  ) async {
    if (_observed && account == _account) return;
    final coldStart = !_observed;
    _observed = true;
    _account = account;
    final epoch = ++_epoch;
    if (account == null) {
      if (!await sp.remove(accountKey)) throw StateError('注销同步状态保存失败');
      return;
    }
    final force = !coldStart || sp.getString(accountKey) != account;
    await synchronize(force: force);
    // 旧账号请求晚返回，不能覆盖新账号的完成标记（包括 A→B→A）。
    if (_epoch != epoch || _account != account) return;
    if (!await sp.setString(accountKey, account)) {
      throw StateError('启动同步账号保存失败');
    }
  }
}
