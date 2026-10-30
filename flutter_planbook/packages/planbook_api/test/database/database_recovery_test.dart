import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:planbook_api/database/database_recovery.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late File file;
  String? previousTemporaryDirectory;

  setUp(() {
    previousTemporaryDirectory = sqlite3.tempDirectory;
    directory = Directory.systemTemp.createTempSync('planbook-recovery-');
    file = File(p.join(directory.path, 'planbook.sqlite'));
  });
  tearDown(() {
    sqlite3.tempDirectory = previousTemporaryDirectory;
    directory.deleteSync(recursive: true);
  });

  Future<void> recover() => recoverDatabaseFile(
    databasePath: file.path,
    temporaryDirectory: directory.path,
  );

  List<Directory> backups() => Directory(
    '${file.path}.recovery',
  ).listSync().whereType<Directory>().toList();

  test('首次安装没有数据库时不创建数据库或备份', () async {
    await recover();
    expect(directory.listSync(), isEmpty);
  });

  test('正常库检查后保留业务数据与未同步 Outbox', () async {
    sqlite3.open(file.path)
      ..execute('CREATE TABLE sync_outbox (payload TEXT NOT NULL)')
      ..execute('INSERT INTO sync_outbox VALUES (?)', ['待同步修改'])
      ..dispose();

    await recover();

    expect(file.existsSync(), isTrue);
    expect(File('${file.path}.corrupt').existsSync(), isFalse);
    final reopened = sqlite3.open(file.path);
    try {
      expect(
        reopened.select('SELECT payload FROM sync_outbox').single['payload'],
        '待同步修改',
      );
    } finally {
      reopened.dispose();
    }
  });

  test('正常 WAL 内的未同步数据不会被恢复流程清理', () async {
    final db = sqlite3.open(file.path);
    addTearDown(db.dispose);
    db
      ..execute('PRAGMA journal_mode=WAL;')
      ..execute('PRAGMA wal_autocheckpoint=0;')
      ..execute('CREATE TABLE sync_outbox (payload TEXT NOT NULL)')
      ..execute('INSERT INTO sync_outbox VALUES (?)', ['只在 WAL 中的新修改']);
    expect(File('${file.path}-wal').existsSync(), isTrue);

    await recover();

    expect(file.existsSync(), isTrue);
    expect(File('${file.path}-wal').existsSync(), isTrue);
    expect(File('${file.path}.corrupt').existsSync(), isFalse);
    final reader = sqlite3.open(file.path);
    try {
      expect(
        reader.select('SELECT payload FROM sync_outbox').single['payload'],
        '只在 WAL 中的新修改',
      );
    } finally {
      reader.dispose();
    }
  });

  test('busy 不判坏也不放行，保留数据库与旧备份', () async {
    final db = sqlite3.open(file.path);
    addTearDown(db.dispose);
    db
      ..execute('CREATE TABLE tasks (title TEXT NOT NULL)')
      ..execute('INSERT INTO tasks VALUES (?)', ['保留任务']);
    final backup = File('${file.path}.corrupt')..writeAsStringSync('已有备份');
    db.execute('BEGIN EXCLUSIVE;');
    try {
      var businessOpened = false;
      await expectLater(
        recover().then((_) => businessOpened = true),
        throwsA(
          isA<DatabaseRecoveryException>().having(
            (e) => e.cause,
            'cause',
            isA<SqliteException>().having((e) => e.resultCode, 'resultCode', 5),
          ),
        ),
      );
      expect(businessOpened, isFalse);
      expect(file.existsSync(), isTrue);
      expect(backup.readAsStringSync(), '已有备份');
      expect(Directory('${file.path}.recovery').existsSync(), isFalse);
    } finally {
      db.execute('ROLLBACK;');
    }
    expect(db.select('SELECT title FROM tasks').single['title'], '保留任务');
  });

  test('WAL 写事务进行中检查正常快照，不清理待提交的数据', () async {
    final db = sqlite3.open(file.path);
    addTearDown(db.dispose);
    db
      ..execute('PRAGMA journal_mode=WAL;')
      ..execute('PRAGMA wal_autocheckpoint=0;')
      ..execute('CREATE TABLE sync_outbox (payload TEXT NOT NULL)')
      ..execute('BEGIN IMMEDIATE;')
      ..execute('INSERT INTO sync_outbox VALUES (?)', ['正在提交的修改']);
    try {
      await recover();
      expect(file.existsSync(), isTrue);
      expect(File('${file.path}-wal').existsSync(), isTrue);
      expect(File('${file.path}.corrupt').existsSync(), isFalse);
      db.execute('COMMIT;');
    } on Object {
      db.execute('ROLLBACK;');
      rethrow;
    }
    expect(
      db.select('SELECT payload FROM sync_outbox').single['payload'],
      '正在提交的修改',
    );
  });

  test('其他读连接持有损坏库时保留可读 WAL 和 Outbox，阻止业务开库', () async {
    final source = File(p.join(directory.path, 'source.sqlite'));
    final db = sqlite3.open(source.path);
    late List<int> mainBytes;
    late List<int> walBytes;
    late int damagedPage;
    late int pageSize;
    try {
      db
        ..execute('CREATE TABLE damaged (value TEXT NOT NULL)')
        ..execute('CREATE TABLE sync_outbox (payload TEXT NOT NULL)')
        ..execute('PRAGMA journal_mode=WAL;')
        ..execute('PRAGMA wal_autocheckpoint=0;')
        ..execute('PRAGMA wal_checkpoint(TRUNCATE);')
        ..execute('INSERT INTO sync_outbox VALUES (?)', ['仍可读的未同步修改']);
      damagedPage =
          db
                  .select(
                    "SELECT rootpage FROM sqlite_schema WHERE name = 'damaged'",
                  )
                  .single['rootpage']
              as int;
      pageSize = db.select('PRAGMA page_size;').single['page_size'] as int;
      // 仅在临时夹具中模拟另一张表的页面损坏，保留 WAL 中完整的 Outbox 页。
      mainBytes = source.readAsBytesSync();
      walBytes = File('${source.path}-wal').readAsBytesSync();
    } finally {
      db.dispose();
    }
    mainBytes[(damagedPage - 1) * pageSize] = 0xff;
    file.writeAsBytesSync(mainBytes);
    File('${file.path}-wal').writeAsBytesSync(walBytes);

    // 模拟仍持有共享库的原生小组件读连接；恢复前待同步数据仍可读取。
    final reader = sqlite3.open(file.path, mode: OpenMode.readOnly);
    try {
      reader.execute('BEGIN;');
      expect(
        reader.select('SELECT payload FROM sync_outbox').single['payload'],
        '仍可读的未同步修改',
      );
      expect(
        () => reader.select('PRAGMA quick_check;'),
        throwsA(isA<SqliteException>()),
      );

      var businessOpened = false;
      await expectLater(
        recover().then((_) => businessOpened = true),
        throwsA(
          isA<DatabaseRecoveryException>().having(
            (e) => e.backupDirectory,
            'backupDirectory',
            isNotNull,
          ),
        ),
      );
      expect(businessOpened, isFalse);
      expect(file.existsSync(), isTrue);
      expect(File('${file.path}.corrupt').existsSync(), isFalse);
      expect(file.readAsBytesSync(), orderedEquals(mainBytes));
      expect(
        File('${file.path}-wal').readAsBytesSync(),
        orderedEquals(walBytes),
      );
      expect(File('${file.path}-shm').existsSync(), isTrue);
      final backup = backups().single;
      expect(
        File(p.join(backup.path, 'planbook.sqlite')).readAsBytesSync(),
        orderedEquals(mainBytes),
      );
      expect(
        File(p.join(backup.path, 'planbook.sqlite-wal')).readAsBytesSync(),
        orderedEquals(walBytes),
      );
      expect(
        File(p.join(backup.path, 'planbook.sqlite-shm')).existsSync(),
        isTrue,
      );
    } finally {
      reader.dispose();
    }
    final reopened = sqlite3.open(file.path);
    try {
      expect(
        reopened.select('SELECT payload FROM sync_outbox').single['payload'],
        '仍可读的未同步修改',
      );
    } finally {
      reopened.dispose();
    }
  });

  test('损坏时保全主库和全部 sidecar，不覆盖旧备份、不放行启动', () {
    const corrupt = 'this is not a sqlite database';
    file.writeAsStringSync(corrupt);
    File('${file.path}-wal').writeAsStringSync('bad wal');
    File('${file.path}-shm').writeAsStringSync('bad shm');
    File('${file.path}-journal').writeAsStringSync('rollback journal');
    final backup = File('${file.path}.corrupt')..writeAsStringSync('旧损坏备份');

    // 注入已确认损坏的结果，避免伪造 rollback journal 影响 SQLite 开库分类。
    expect(
      () => DatabaseFileRecovery(check: (_) => false).recover(file.path),
      throwsA(isA<DatabaseRecoveryException>()),
    );

    expect(file.readAsStringSync(), corrupt);
    expect(backup.readAsStringSync(), '旧损坏备份');
    expect(File('${file.path}-wal').readAsStringSync(), 'bad wal');
    expect(File('${file.path}-shm').readAsStringSync(), 'bad shm');
    expect(File('${file.path}-journal').readAsStringSync(), 'rollback journal');
    final archive = backups().single;
    expect(
      File(p.join(archive.path, 'planbook.sqlite')).readAsStringSync(),
      corrupt,
    );
    expect(
      File(p.join(archive.path, 'planbook.sqlite-wal')).readAsStringSync(),
      'bad wal',
    );
    expect(
      File(p.join(archive.path, 'planbook.sqlite-shm')).readAsStringSync(),
      'bad shm',
    );
    expect(
      File(p.join(archive.path, 'planbook.sqlite-journal')).readAsStringSync(),
      'rollback journal',
    );
    final manifest =
        jsonDecode(
              File(p.join(archive.path, 'manifest.json')).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(manifest['copyCompleted'], isTrue);
    expect(manifest['consistentSnapshot'], isFalse);
  });

  test('每次启动仍检查，后续损坏会阻止启动且重复保全不覆盖备份', () async {
    sqlite3.open(file.path).dispose();
    await recover();
    expect(file.existsSync(), isTrue);
    file.writeAsStringSync('later corrupted');
    await expectLater(recover(), throwsA(isA<DatabaseRecoveryException>()));
    final first = backups().single;
    file.writeAsStringSync('another corrupted state');
    await expectLater(recover(), throwsA(isA<DatabaseRecoveryException>()));
    expect(backups(), hasLength(2));
    expect(
      File(p.join(first.path, 'planbook.sqlite')).readAsStringSync(),
      'later corrupted',
    );
    expect(file.readAsStringSync(), 'another corrupted state');
  });

  test('确认损坏后不再通过删除 sidecar 复查，原文件全部保留', () {
    file.writeAsStringSync('主库保留');
    File('${file.path}-wal').writeAsStringSync('wal');
    File('${file.path}-shm').writeAsStringSync('shm');
    var checks = 0;
    final recovery = DatabaseFileRecovery(
      check: (path) {
        expect(path, file.path);
        checks++;
        return false;
      },
    );
    expect(
      () => recovery.recover(file.path),
      throwsA(isA<DatabaseRecoveryException>()),
    );
    expect(checks, 1);
    expect(file.readAsStringSync(), '主库保留');
    expect(File('${file.path}-wal').readAsStringSync(), 'wal');
    expect(File('${file.path}-shm').readAsStringSync(), 'shm');
    expect(File('${file.path}.corrupt').existsSync(), isFalse);
  });

  test('旧隔离路径被目录占用时不再尝试重命名或删除主库', () {
    file.writeAsStringSync('bad database');
    final backupDirectory = Directory('${file.path}.corrupt')..createSync();
    File(p.join(backupDirectory.path, 'keep')).writeAsStringSync('保留');
    expect(
      () => DatabaseFileRecovery(check: (_) => false).recover(file.path),
      throwsA(isA<DatabaseRecoveryException>()),
    );
    expect(file.readAsStringSync(), 'bad database');
    expect(backupDirectory.existsSync(), isTrue);
    expect(File(p.join(backupDirectory.path, 'keep')).readAsStringSync(), '保留');
    expect(backups(), hasLength(1));
  });

  test('检查异常包含损坏文字也不判坏，不备份或继续启动', () {
    file.writeAsStringSync('主库');
    final recovery = DatabaseFileRecovery(
      check: (_) => throw const FileSystemException('malformed CORRUPT 路径错误'),
    );
    expect(
      () => recovery.recover(file.path),
      throwsA(
        isA<DatabaseRecoveryException>().having(
          (e) => e.cause,
          'cause',
          isA<FileSystemException>(),
        ),
      ),
    );
    expect(file.readAsStringSync(), '主库');
    expect(File('${file.path}.corrupt').existsSync(), isFalse);
    expect(Directory('${file.path}.recovery').existsSync(), isFalse);
  });

  test('备份根目录被占用时抛错，保留主库、WAL 和旧备份', () async {
    file.writeAsStringSync('bad database');
    File('${file.path}-wal').writeAsStringSync('pending wal');
    File('${file.path}.corrupt').writeAsStringSync('旧备份');
    File('${file.path}.recovery').writeAsStringSync('占用备份路径');
    var businessOpened = false;
    await expectLater(
      recover().then((_) => businessOpened = true),
      throwsA(
        isA<DatabaseRecoveryException>().having(
          (e) => e.cause,
          'cause',
          isA<FileSystemException>(),
        ),
      ),
    );
    expect(businessOpened, isFalse);
    expect(file.readAsStringSync(), 'bad database');
    expect(File('${file.path}-wal').readAsStringSync(), 'pending wal');
    expect(File('${file.path}.corrupt').readAsStringSync(), '旧备份');
    expect(File('${file.path}.recovery').readAsStringSync(), '占用备份路径');
  });

  test('部分备份失败保留所有源文件和已拷贝文件，无完成标记', () {
    file.writeAsStringSync('bad database');
    File('${file.path}-wal').writeAsStringSync('pending wal');
    Directory('${file.path}-shm').createSync();
    expect(
      () => DatabaseFileRecovery(check: (_) => false).recover(file.path),
      throwsA(
        isA<DatabaseRecoveryException>()
            .having((e) => e.backupDirectory, 'backupDirectory', isNotNull)
            .having((e) => e.cause, 'cause', isA<FileSystemException>()),
      ),
    );
    expect(file.readAsStringSync(), 'bad database');
    expect(File('${file.path}-wal').readAsStringSync(), 'pending wal');
    expect(Directory('${file.path}-shm').existsSync(), isTrue);
    final archive = backups().single;
    expect(
      File(p.join(archive.path, 'planbook.sqlite')).readAsStringSync(),
      'bad database',
    );
    expect(
      File(p.join(archive.path, 'planbook.sqlite-wal')).readAsStringSync(),
      'pending wal',
    );
    expect(File(p.join(archive.path, 'manifest.json')).existsSync(), isFalse);
  });

  test('主库丢失但 WAL 尚在时阻止创建空库，保留日志', () async {
    File('${file.path}-wal').writeAsStringSync('可能可恢复的数据');
    var businessOpened = false;
    await expectLater(
      recover().then((_) => businessOpened = true),
      throwsA(isA<DatabaseRecoveryException>()),
    );
    expect(businessOpened, isFalse);
    expect(file.existsSync(), isFalse);
    expect(File('${file.path}-wal').readAsStringSync(), '可能可恢复的数据');
    expect(Directory('${file.path}.recovery').existsSync(), isFalse);
  });

  test('I/O 检查失败不标记损坏也不放行启动', () {
    file.writeAsStringSync('主库');
    final error = SqliteException(10, 'disk I/O error');
    expect(
      () => DatabaseFileRecovery(check: (_) => throw error).recover(file.path),
      throwsA(
        isA<DatabaseRecoveryException>().having(
          (e) => e.cause,
          'cause',
          same(error),
        ),
      ),
    );
    expect(file.readAsStringSync(), '主库');
    expect(Directory('${file.path}.recovery').existsSync(), isFalse);
  });

  test('数据库符号链接不跟随、不改动目标文件', () async {
    final target = File(p.join(directory.path, 'target.sqlite'))
      ..writeAsStringSync('保留目标文件');
    Link(file.path).createSync(target.path);
    await expectLater(recover(), throwsA(isA<DatabaseRecoveryException>()));
    expect(target.readAsStringSync(), '保留目标文件');
    expect(Link(file.path).existsSync(), isTrue);
    expect(Directory('${file.path}.recovery').existsSync(), isFalse);
  });

  test('并发请求合并且等待恢复真正完成，不缓存完成状态', () async {
    var calls = 0;
    final started = Completer<void>();
    final finish = Completer<void>();
    final scheduler = DatabaseRecoveryScheduler(
      run:
          ({
            required databasePath,
            required temporaryDirectory,
          }) async {
            calls++;
            if (!started.isCompleted) started.complete();
            await finish.future;
          },
    );
    final first = scheduler.recover(
      databasePath: file.path,
      temporaryDirectory: directory.path,
    );
    final second = scheduler.recover(
      databasePath: file.path,
      temporaryDirectory: directory.path,
    );
    expect(identical(first, second), isTrue);
    await started.future;
    var completed = false;
    unawaited(first.then((_) => completed = true));
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    finish.complete();
    await Future.wait([first, second]);
    await scheduler.recover(
      databasePath: file.path,
      temporaryDirectory: directory.path,
    );
    expect(calls, 2);
  });

  test('任务失败会传给原调用者，后续排队任务与同路径重试仍执行', () async {
    final entered = Completer<void>();
    final finish = Completer<void>();
    final calls = <String>[];
    final secondPath = p.join(directory.path, 'second.sqlite');
    final scheduler = DatabaseRecoveryScheduler(
      run:
          ({
            required databasePath,
            required temporaryDirectory,
          }) async {
            calls.add(databasePath);
            if (calls.length == 1) {
              entered.complete();
              await finish.future;
              throw const FileSystemException('恢复失败');
            }
          },
    );
    final first = scheduler.recover(
      databasePath: file.path,
      temporaryDirectory: directory.path,
    );
    final failure = expectLater(first, throwsA(isA<FileSystemException>()));
    await entered.future;
    final second = scheduler.recover(
      databasePath: secondPath,
      temporaryDirectory: directory.path,
    );
    await Future<void>.delayed(Duration.zero);
    expect(calls, [file.path]);
    finish.complete();
    await failure;
    await second;
    await scheduler.recover(
      databasePath: file.path,
      temporaryDirectory: directory.path,
    );
    expect(calls, [file.path, secondPath, file.path]);
  });
}
