import 'dart:io';

import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:database_planbook_api/task/database_task_today_api.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

/// 用用户真实数据库副本复现「每月任务不显示」
///
/// 数据库来自 iOS 模拟器 App Group 容器，包含用户今天创建的
/// 「每月 2 日」「每月 6 日」「每月 8 日」「每月 31 日」等任务。
void main() {
  const dbPath = '/tmp/planbook_db_copy/planbook.sqlite';

  test('真实数据库：每月 8 日在 8/8、9/8 应显示', () async {
    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    final outboxApi = OutboxApi(db: db);
    final tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
    final taskApi = DatabaseTaskApi(
      db: db,
      tagApi: tagApi,
      outboxApi: outboxApi,
    );
    final todayApi = DatabaseTaskTodayApi(
      db: db,
      tagApi: tagApi,
      outboxApi: outboxApi,
    );

    // 1. 现状：每月 8 日的实例有哪些
    final taskRow = await (db.select(
      db.tasks,
    )..where((t) => t.title.equals('每月 8 日') & t.deletedAt.isNull())).get();
    print('每月 8 日任务数: ${taskRow.length}');
    for (final t in taskRow) {
      final occs = await (db.select(
        db.taskOccurrences,
      )..where((o) => o.taskId.equals(t.id))).get();
      print(
        '  task ${t.id}: start=${t.startAt?.format()} '
        'rule=${t.recurrenceRule?.toJson()}',
      );
      for (final o in occs) {
        print(
          '    occ=${o.occurrenceAt.format()} '
          'start=${o.startAt?.format()} end=${o.endAt?.format()} '
          'deleted=${o.deletedAt?.format()}',
        );
      }
    }

    // 2. 预生成前：8/8 查询
    final before = await todayApi
        .getTaskEntities(date: Jiffy.parse('2026-08-08'))
        .first;
    print('8/8 预生成前显示任务: ${before.map((e) => e.task.title).toList()}');

    // 3. 显式预生成后再查
    await taskApi.preGenerateTaskOccurrences(
      fromDate: Jiffy.parse('2026-08-08'),
    );

    final occsAfter = await db.select(db.taskOccurrences).get();
    print('预生成后实例总数: ${occsAfter.length}');

    final after = await todayApi
        .getTaskEntities(date: Jiffy.parse('2026-08-08'))
        .first;
    print('8/8 预生成后显示任务: ${after.map((e) => e.task.title).toList()}');

    final after98 = await todayApi
        .getTaskEntities(date: Jiffy.parse('2026-09-08'))
        .first;
    print('9/8 预生成后显示任务: ${after98.map((e) => e.task.title).toList()}');

    await db.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
