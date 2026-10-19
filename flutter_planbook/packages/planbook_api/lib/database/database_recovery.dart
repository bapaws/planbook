import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

typedef _RecoveryInput = ({String databasePath, String temporaryDirectory});

typedef DatabaseRecoveryRunner =
    Future<void> Function({
      required String databasePath,
      required String temporaryDirectory,
    });

final _scheduler = DatabaseRecoveryScheduler();

/// 在独立 isolate 完整执行检查与恢复；完成之前调用方不能打开业务数据库。
Future<void> recoverDatabaseFile({
  required String databasePath,
  required String temporaryDirectory,
}) => _scheduler.recover(
  databasePath: databasePath,
  temporaryDirectory: temporaryDirectory,
);

/// 合并同一文件的进行中请求，完整串行执行不同文件的检查和恢复。
class DatabaseRecoveryScheduler {
  DatabaseRecoveryScheduler({DatabaseRecoveryRunner? run})
    : _run = run ?? _runRecovery;

  final DatabaseRecoveryRunner _run;
  final _pendingRecoveries = <String, Future<void>>{};
  Future<void> _recoveryTail = Future.value();

  Future<void> recover({
    required String databasePath,
    required String temporaryDirectory,
  }) {
    final path = p.normalize(p.absolute(databasePath));
    return _pendingRecoveries.putIfAbsent(path, () {
      // SQLite 的临时目录配置涉及原生全局状态，检查任务之间也保持串行。
      final request = _recoveryTail
          .then(
            (_) => _run(
              databasePath: path,
              temporaryDirectory: temporaryDirectory,
            ),
          )
          .whenComplete(() {
            _pendingRecoveries.remove(path);
          });
      // 一次失败不能阻止后续重试；原调用者仍收到该次失败。
      _recoveryTail = request.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      );
      return request;
    });
  }
}

Future<void> _runRecovery({
  required String databasePath,
  required String temporaryDirectory,
}) => compute(
  _recoverInBackground,
  (databasePath: databasePath, temporaryDirectory: temporaryDirectory),
  debugLabel: 'database-integrity-check',
);

void _recoverInBackground(_RecoveryInput input) {
  // 此处不调用 path_provider 或平台通道，动态库由本 isolate 的 sqlite3 绑定打开。
  // Android 的旧版本加载兼容处理已在主 isolate 完成。
  sqlite3.tempDirectory = input.temporaryDirectory;
  DatabaseFileRecovery().recover(input.databasePath);
}

/// 检查或保全失败时阻止启动；原始文件始终留在原路径。
class DatabaseRecoveryException implements Exception {
  DatabaseRecoveryException({
    required this.databasePath,
    required this.reason,
    this.backupDirectory,
    this.cause,
  });

  final String databasePath;
  final String reason;
  final String? backupDirectory;
  final Object? cause;

  @override
  String toString() =>
      'DatabaseRecoveryException: $reason; database=$databasePath; '
      'backup=$backupDirectory; cause=$cause';
}

/// 只读检查，损坏时保全文件并阻止开库，不在线清理或替换共享库。
class DatabaseFileRecovery {
  DatabaseFileRecovery({bool Function(String)? check})
    : _check = check ?? _quickCheckOk;

  final bool Function(String) _check;

  void recover(String path) {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      // 主库缺失但日志仍在时不能按首次安装创建空库，否则会掩盖可恢复数据。
      for (final suffix in _sidecars) {
        if (FileSystemEntity.typeSync('$path$suffix', followLinks: false) !=
            FileSystemEntityType.notFound) {
          throw DatabaseRecoveryException(
            databasePath: path,
            reason: '主库缺失但数据库日志仍在，保留现场并停止启动',
          );
        }
      }
      return;
    }
    if (type != FileSystemEntityType.file) {
      throw DatabaseRecoveryException(
        databasePath: path,
        reason: '数据库路径不是普通文件，停止启动',
      );
    }

    final bool healthy;
    try {
      healthy = _check(path);
    } on Object catch (error) {
      // busy、locked、I/O 等表示检查未完成，既不能判坏，也不能放行开库。
      throw DatabaseRecoveryException(
        databasePath: path,
        reason: '完整性检查未完成，保留原文件并停止启动',
        cause: error,
      );
    }
    if (healthy) return;

    final backupDirectory = _preserveFiles(path);
    // 小组件等进程可能持有共享库，不能删除 WAL、重命名原库或自动建空库。
    throw DatabaseRecoveryException(
      databasePath: path,
      reason: '确认数据库损坏，已保全文件，停止启动等待恢复',
      backupDirectory: backupDirectory,
    );
  }

  static bool _quickCheckOk(String path) {
    try {
      final db = sqlite3.open(path, mode: OpenMode.readOnly);
      try {
        final rows = db.select('PRAGMA quick_check;');
        if (rows.isEmpty) {
          throw StateError('完整性检查没有返回结果');
        }
        return rows.length == 1 && rows.single.columnAt(0)?.toString() == 'ok';
      } finally {
        db.dispose();
      }
    } on SqliteException catch (e) {
      if (_isCorruptSqliteCode(e.resultCode) ||
          _isCorruptSqliteCode(e.extendedResultCode)) {
        return false;
      }
      rethrow;
    }
  }

  static bool _isCorruptSqliteCode(int code) {
    const sqliteCorrupt = 11;
    const sqliteNotADb = 26;
    final primaryCode = code & 0xff;
    return primaryCode == sqliteCorrupt || primaryCode == sqliteNotADb;
  }

  static const _sidecars = ['-wal', '-shm', '-journal'];

  static String _preserveFiles(String path) {
    Directory? backup;
    try {
      final root = Directory('$path.recovery');
      final type = FileSystemEntity.typeSync(root.path, followLinks: false);
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.directory) {
        throw FileSystemException('备份根路径不是普通目录', root.path);
      }
      root.createSync();
      // createTemp 原子创建唯一目录，不覆盖旧 .corrupt 或其他恢复尝试的备份。
      backup = root.createTempSync('attempt-');
      final copiedFiles = <String>[];
      for (final suffix in ['', ..._sidecars]) {
        final sourcePath = '$path$suffix';
        final type = FileSystemEntity.typeSync(sourcePath, followLinks: false);
        if (type == FileSystemEntityType.notFound && suffix.isNotEmpty) {
          continue;
        }
        if (type != FileSystemEntityType.file) {
          throw FileSystemException('待保全文件缺失或不是普通文件', sourcePath);
        }
        final name = p.basename(sourcePath);
        final copy = File(sourcePath).copySync(p.join(backup.path, name));
        final output = copy.openSync(mode: FileMode.append);
        try {
          output.flushSync();
        } finally {
          output.closeSync();
        }
        copiedFiles.add(name);
      }
      // 其他进程仍可能写入；原始拷贝仅用于保全，不能冒充一致性恢复快照。
      // 最后写完成标记；中途失败保留部分文件且没有完成标记，不能据此放行。
      File(p.join(backup.path, 'manifest.json')).writeAsStringSync(
        jsonEncode({
          'databasePath': path,
          'copiedFiles': copiedFiles,
          'copyCompleted': true,
          'consistentSnapshot': false,
        }),
        flush: true,
      );
      return backup.path;
    } on Object catch (error) {
      throw DatabaseRecoveryException(
        databasePath: path,
        reason: '损坏文件保全失败，保留原文件和部分备份并停止启动',
        backupDirectory: backup?.path,
        cause: error,
      );
    }
  }
}
