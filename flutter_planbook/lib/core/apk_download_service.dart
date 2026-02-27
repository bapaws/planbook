import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_planbook/core/model/app_channel.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 封装 APK 版本获取与下载：获取版本、判断是否有新版本、enqueue 下载；
/// 启动时调用 [start] 后，enqueue 的任务在原生层后台执行，完成后由此处调起安装。
class ApkDownloadService {
  ApkDownloadService._();

  static const String groupPlanbookApk = 'planbook_apk';
  static const _versionUrl = 'https://res.bapaws.com/planbook/apk_version.txt';
  static const _versionCacheHours = 24;
  static const _keyCompletedApkVersion = 'apk_download_completed_version';

  static bool _started = false;
  static SharedPreferences? _sp;
  static StreamSubscription<TaskUpdate>? _updatesSubscription;
  static final _progressController = StreamController<double>.broadcast();

  /// 进度流：0~1 为进度，-1 表示失败/取消；由 AppBloc 订阅并更新 state。
  static Stream<double> get progressStream => _progressController.stream;

  /// 获取远端版本；若 24 小时内已拉过则用缓存。需传入 [SharedPreferences]。
  static Future<String?> fetchVersion(SharedPreferences sp) async {
    if (!AppChannel.isCloud) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final timestamp = sp.getInt('latest_get_apk_version_timestamp');
    if (timestamp != null &&
        now - timestamp < 1000 * 60 * 60 * _versionCacheHours) {
      return sp.getString('latest_apk_version');
    }
    final response = await http.get(Uri.parse(_versionUrl));
    if (response.statusCode != 200) return null;
    final version = response.body.trim();
    await sp.setInt('latest_get_apk_version_timestamp', now);
    await sp.setString('latest_apk_version', version);
    return version;
  }

  /// 远端版本是否大于当前应用版本。支持 "2.5.1" 或 "2.5.1+97" 格式。
  static Future<bool> hasNewVersion(String? remoteVersion) async {
    if (remoteVersion == null || remoteVersion.isEmpty) return false;
    final info = await PackageInfo.fromPlatform();
    return _isVersionGreaterThan(
      remoteVersion,
      info.version,
      info.buildNumber,
    );
  }

  static bool _isVersionGreaterThan(
    String remote,
    String currentVersion,
    String currentBuild,
  ) {
    final remoteParts = remote.split('+');
    final remoteVer = remoteParts[0].trim();
    final remoteBuild = remoteParts.length > 1 ? remoteParts[1].trim() : null;
    final vCompare = _compareVersionSegments(
      remoteVer.split('.').map((e) => int.tryParse(e) ?? 0).toList(),
      currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList(),
    );
    if (vCompare != 0) return vCompare > 0;
    if (remoteBuild != null) {
      final r = int.tryParse(remoteBuild) ?? 0;
      final c = int.tryParse(currentBuild) ?? 0;
      return r > c;
    }
    return false;
  }

  static int _compareVersionSegments(List<int> a, List<int> b) {
    for (var i = 0; i < a.length || i < b.length; i++) {
      final va = i < a.length ? a[i] : 0;
      final vb = i < b.length ? b[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  /// 将指定版本的 APK 加入下载队列；下载在后台执行，完成后由 [start] 的监听调起安装。
  /// 仅当该版本曾收到过 [TaskStatus.complete]（已记录在 [SharedPreferences]）且文件仍存在时才直接调起安装，
  /// 避免暂停/失败后残留的未完成文件被误当作已下载。
  static Future<bool> downloadApk(String version, SharedPreferences sp) async {
    if (!AppChannel.isCloud) return false;

    final filename = 'planbook-$version.apk';
    final dir = await getTemporaryDirectory();
    final savePath = p.join(dir.path, filename);
    final completedVersion = sp.getString(_keyCompletedApkVersion);
    if (completedVersion == version && File(savePath).existsSync()) {
      _progressController.add(1);
      unawaited(OpenFilex.open(savePath));
      return true;
    }
    final task = DownloadTask(
      url: 'https://res.bapaws.com/planbook/planbook-$version.apk',
      filename: filename,
      baseDirectory: BaseDirectory.temporary,
      group: groupPlanbookApk,
      updates: Updates.statusAndProgress,
      allowPause: true,
    );
    return FileDownloader().enqueue(task);
  }

  /// 在 App 启动时调用一次，启动 FileDownloader 并监听 planbook_apk 任务完成/进度。
  /// [sp] 用于在收到 [TaskStatus.complete] 时记录该版本已完整下载，供 [downloadApk] 判断是否可跳过下载。
  /// 按 package 要求先注册 listener 再调用 start；应用进程退出时无需 stop/cancel，
  /// 如需显式销毁（如测试）可调用 [stop]。
  static void start(SharedPreferences sp) {
    if (!AppChannel.isCloud) return;
    if (_started) return;
    _started = true;
    _sp = sp;
    _updatesSubscription = FileDownloader().updates.listen(_onUpdate);
    FileDownloader().start();
  }

  /// 取消 updates 订阅；仅在有显式关闭需求时调用（如测试），正常应用退出无需调用。
  static void stop() {
    if (!AppChannel.isCloud) return;
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _sp = null;
    _started = false;
  }

  static void _onUpdate(TaskUpdate update) {
    if (!AppChannel.isCloud) return;
    if (update.task.group != groupPlanbookApk) return;

    if (update is TaskProgressUpdate) {
      final p = update.progress;
      if (p >= 0 && p <= 1) _progressController.add(p);
    } else if (update is TaskStatusUpdate) {
      if (update.status == TaskStatus.complete) {
        final version = _versionFromFilename(update.task.filename);
        if (version != null && _sp != null) {
          _sp!.setString(_keyCompletedApkVersion, version);
        }
        _progressController.add(1);
        update.task.filePath().then(OpenFilex.open);
      } else if (update.status == TaskStatus.failed ||
          update.status == TaskStatus.canceled ||
          update.status == TaskStatus.notFound) {
        _progressController.add(-1);
      }
    }
  }

  /// 从 filename（如 planbook-2.5.2.apk）解析出版本号。
  static String? _versionFromFilename(String filename) {
    if (!filename.startsWith('planbook-') || !filename.endsWith('.apk')) {
      return null;
    }
    return filename.substring(
      'planbook-'.length,
      filename.length - '.apk'.length,
    );
  }
}
