import 'dart:convert';

import 'package:database_planbook_api/task/database_task_delay_api.dart';
import 'package:database_planbook_api/task/database_task_today_api.dart';
import 'package:database_planbook_api/task/recurrence_rule_calculator.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

import '../test_helper.dart';

/// 诊断测试：重复任务「数据库有数据但 UI 不显示」
///
/// 针对当前（未修改的）生产代码验证以下假设：
/// T1: 旧格式 daysOfWeek（int 数组）的规则 JSON 是否会让 fromJson 崩溃
/// T2: 数据库里存在旧格式规则的任务时，preGenerate 是否会被整体拖垮，
///     导致健康任务也生成不出实例
/// T3: 旧格式任务出现在查询结果里时，今日列表 Stream 是否会直接报错
/// T4: 健康每月任务（8/2 起、每月 6 号）能否在 8/6 正常显示（基线，应通过）
/// T5: ensureSoftDeleteOccurrence 对同一天调用两次是否触发 UNIQUE 崩溃
///     （对应控制台 SqliteException 2067）
void main() {
  group('诊断：重复任务不显示', () {
    test('T1: 旧格式 daysOfWeek int 数组的规则 JSON 应能正常解析', () {
      final json = jsonDecode('''
        {
          "frequency": "weekly",
          "interval": 1,
          "daysOfWeek": [1, 3]
        }
      ''') as Map<String, dynamic>;

      final rule = RecurrenceRule.fromJson(json);

      expect(rule.daysOfWeek, hasLength(2));
    });

    test('T2: 存在旧格式任务时，健康任务的实例也应能预生成', () async {
      final apis = createTestApis();
      final db = apis.db;

      // 旧版本 App 创建的每周重复任务（daysOfWeek 为 int 数组）
      final legacyTask = Task(
        id: const Uuid().v4(),
        title: 'legacy',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-01T10:00:00'),
        endAt: Jiffy.parse('2026-08-01T11:00:00'),
        isAllDay: false,
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await db.into(db.tasks).insert(legacyTask);
      // 用原生 SQL 写入旧格式规则 JSON
      await db.customUpdate(
        'UPDATE tasks SET recurrence_rule = ? WHERE id = ?',
        variables: [
          Variable.withString(
            '{"frequency":"weekly","interval":1,"daysOfWeek":[1,3]}',
          ),
          Variable.withString(legacyTask.id),
        ],
        updates: {db.tasks},
      );

      // 健康的每月重复任务：8/2 起、每月 6 号
      final healthyTask = Task(
        id: const Uuid().v4(),
        title: 'healthy',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-02T10:00:00'),
        endAt: Jiffy.parse('2026-08-02T11:00:00'),
        isAllDay: false,
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [6],
        ),
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await db.into(db.tasks).insert(healthyTask);

      await apis.taskApi.preGenerateTaskOccurrences(
        fromDate: Jiffy.parse('2026-08-06'),
      );

      final occurrences = await (db.select(
        db.taskOccurrences,
      )..where((t) => t.taskId.equals(healthyTask.id))).get();

      // 健康任务应在 8/6 生成出实例
      expect(
        occurrences.any(
          (o) => o.occurrenceAt.isSame(
            Jiffy.parse('2026-08-06'),
            unit: Unit.day,
          ),
        ),
        isTrue,
        reason: '健康任务在 8/6 应有实例，旧格式任务不应影响它',
      );

      await db.close();
    });

    test('T3: 查询结果含旧格式任务时，今日列表 Stream 应正常发出数据', () async {
      final apis = createTestApis();
      final db = apis.db;
      final todayApi = DatabaseTaskTodayApi(
        db: db,
        tagApi: apis.tagApi,
        outboxApi: apis.outboxApi,
      );

      final date = Jiffy.parse('2026-08-06');

      // 旧格式任务 + 8/6 的实例行
      final legacyTask = Task(
        id: const Uuid().v4(),
        title: 'legacy',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-01T10:00:00'),
        endAt: Jiffy.parse('2026-08-01T11:00:00'),
        isAllDay: false,
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await db.into(db.tasks).insert(legacyTask);
      await db.customUpdate(
        'UPDATE tasks SET recurrence_rule = ? WHERE id = ?',
        variables: [
          Variable.withString(
            '{"frequency":"weekly","interval":1,"daysOfWeek":[1,3]}',
          ),
          Variable.withString(legacyTask.id),
        ],
        updates: {db.tasks},
      );
      await db
          .into(db.taskOccurrences)
          .insert(
            TaskOccurrence(
              id: const Uuid().v4(),
              taskId: legacyTask.id,
              occurrenceAt: date.startOf(Unit.day),
              startAt: Jiffy.parse('2026-08-06T10:00:00'),
              endAt: Jiffy.parse('2026-08-06T11:00:00'),
              createdAt: Jiffy.now(),
            ),
          );

      // 健康任务 + 8/6 的实例行
      final healthyTask = Task(
        id: const Uuid().v4(),
        title: 'healthy',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-02T10:00:00'),
        endAt: Jiffy.parse('2026-08-02T11:00:00'),
        isAllDay: false,
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [6],
        ),
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await db.into(db.tasks).insert(healthyTask);
      await db
          .into(db.taskOccurrences)
          .insert(
            TaskOccurrence(
              id: const Uuid().v4(),
              taskId: healthyTask.id,
              occurrenceAt: date.startOf(Unit.day),
              startAt: Jiffy.parse('2026-08-06T10:00:00'),
              endAt: Jiffy.parse('2026-08-06T11:00:00'),
              createdAt: Jiffy.now(),
            ),
          );

      final entities = await todayApi.getTaskEntities(date: date).first;

      // 旧格式任务不应让整个列表 Stream 崩溃，健康任务必须能显示
      expect(
        entities.any((e) => e.task.id == healthyTask.id),
        isTrue,
        reason: '健康任务必须出现在 8/6 的列表里',
      );

      await db.close();
    });

    test('T4: 基线——健康每月任务（8/2 起、每月 6 号）在 8/6 正常显示', () async {
      final apis = createTestApis();
      final db = apis.db;
      final todayApi = DatabaseTaskTodayApi(
        db: db,
        tagApi: apis.tagApi,
        outboxApi: apis.outboxApi,
      );

      final task = Task(
        id: const Uuid().v4(),
        title: 'healthy',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-02T10:00:00'),
        endAt: Jiffy.parse('2026-08-02T11:00:00'),
        isAllDay: false,
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [6],
        ),
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await apis.taskApi.create(task: task);
      // create 里 preGenerate 是 unawaited，这里显式再等一次确保完成
      await apis.taskApi.preGenerateTaskOccurrences(
        fromDate: Jiffy.parse('2026-08-06'),
      );

      final entities = await todayApi
          .getTaskEntities(date: Jiffy.parse('2026-08-06'))
          .first;

      expect(
        entities.any((e) => e.task.id == task.id),
        isTrue,
        reason: '基线链路（生成→查询）必须通畅',
      );

      await db.close();
    });

    test(
      'T11: 每月 6 号 + 残留周四，后续月份（9/6）仍应显示',
      () async {
        final apis = createTestApis();
        final db = apis.db;
        final todayApi = DatabaseTaskTodayApi(
          db: db,
          tagApi: apis.tagApi,
          outboxApi: apis.outboxApi,
        );

        final task = Task(
          id: const Uuid().v4(),
          title: 'monthly-6th-with-weekday',
          layer: 0,
          childCount: 0,
          order: 0,
          startAt: Jiffy.parse('2026-08-06T00:00:00'),
          endAt: Jiffy.parse('2026-08-06T23:59:59'),
          isAllDay: true,
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfMonth: const [6],
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.thursday),
            ],
          ),
          alarms: const [],
          createdAt: Jiffy.now(),
        );
        await apis.taskApi.create(task: task);
        await apis.taskApi.preGenerateTaskOccurrences(
          fromDate: Jiffy.parse('2026-08-06'),
        );

        final onAug6 = await todayApi
            .getTaskEntities(date: Jiffy.parse('2026-08-06'))
            .first;
        final onSep6 = await todayApi
            .getTaskEntities(date: Jiffy.parse('2026-09-06'))
            .first;

        expect(
          onAug6.any((e) => e.task.id == task.id),
          isTrue,
          reason: '创建日 8/6 应显示',
        );
        expect(
          onSep6.any((e) => e.task.id == task.id),
          isTrue,
          reason: '9/6 不是周四，但 daysOfMonth 优先，仍应显示',
        );

        await db.close();
      },
    );

    test(
      'T12: 6 号创建的每月 8 号（含残留周四），8/8 应显示',
      () async {
        final apis = createTestApis();
        final db = apis.db;
        final todayApi = DatabaseTaskTodayApi(
          db: db,
          tagApi: apis.tagApi,
          outboxApi: apis.outboxApi,
        );

        final task = Task(
          id: const Uuid().v4(),
          title: 'monthly-8th-with-weekday',
          layer: 0,
          childCount: 0,
          order: 0,
          startAt: Jiffy.parse('2026-08-06T00:00:00'),
          endAt: Jiffy.parse('2026-08-06T23:59:59'),
          isAllDay: true,
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfMonth: const [8],
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.thursday),
            ],
          ),
          alarms: const [],
          createdAt: Jiffy.now(),
        );
        await apis.taskApi.create(task: task);
        await apis.taskApi.preGenerateTaskOccurrences(
          fromDate: Jiffy.parse('2026-08-06'),
        );

        final onAug8 = await todayApi
            .getTaskEntities(date: Jiffy.parse('2026-08-08'))
            .first;
        final onSep8 = await todayApi
            .getTaskEntities(date: Jiffy.parse('2026-09-08'))
            .first;

        expect(
          onAug8.any((e) => e.task.id == task.id),
          isTrue,
          reason: '8/8（周六）不应因残留周四而消失',
        );
        expect(
          onSep8.any((e) => e.task.id == task.id),
          isTrue,
          reason: '9/8 仍应显示',
        );

        await db.close();
      },
    );

    test('T6: 预生成实例的时间不应被偏移到前一天', () async {
      final apis = createTestApis();
      final db = apis.db;

      // 任务起始时间带有时分（10:00-11:00），8/2 起、每月 6 号
      final task = Task(
        id: const Uuid().v4(),
        title: 'timed',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-02T10:00:00'),
        endAt: Jiffy.parse('2026-08-02T11:00:00'),
        isAllDay: false,
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [6],
        ),
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await apis.taskApi.create(task: task);
      await apis.taskApi.preGenerateTaskOccurrences(
        fromDate: Jiffy.parse('2026-08-06'),
      );

      final occurrences = await (db.select(
        db.taskOccurrences,
      )..where((t) => t.taskId.equals(task.id))).get();

      expect(occurrences, isNotEmpty);
      for (final o in occurrences) {
        // 实例的 startAt/endAt 必须与 occurrenceAt 是同一天
        expect(
          o.startAt!.isSame(o.occurrenceAt, unit: Unit.day),
          isTrue,
          reason:
              '实例 ${o.occurrenceAt.format()} 的 startAt 偏到了 '
              '${o.startAt!.format()}（diff 按 24 小时截断导致少算一天）',
        );
        expect(
          o.endAt!.isSame(o.occurrenceAt, unit: Unit.day),
          isTrue,
          reason: '实例 ${o.occurrenceAt.format()} 的 endAt 偏到了前一天',
        );
      }

      await db.close();
    });

    test('T7: 6 号创建的「每月 2 号」任务，查看 8/2 时能否显示', () async {
      final apis = createTestApis();
      final db = apis.db;
      final todayApi = DatabaseTaskTodayApi(
        db: db,
        tagApi: apis.tagApi,
        outboxApi: apis.outboxApi,
      );

      // 今天 8/6 创建的任务（startDate=8/6），规则每月 2 号
      final task = Task(
        id: const Uuid().v4(),
        title: 'monthly-2nd',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-06T00:00:00'),
        endAt: Jiffy.parse('2026-08-06T23:59:59'),
        isAllDay: true,
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [2],
        ),
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await apis.taskApi.create(task: task);
      await apis.taskApi.preGenerateTaskOccurrences(
        fromDate: Jiffy.parse('2026-08-02'),
      );

      final entities = await todayApi
          .getTaskEntities(date: Jiffy.parse('2026-08-02'))
          .first;

      // 8/2 早于任务起始日 8/6 —— 当前逻辑下不显示
      // 这个测试记录的是「现状行为」，供判断这是否是产品预期
      final visible = entities.any((e) => e.task.id == task.id);
      print('T7 现状：8/2 查看时任务${visible ? "显示" : "不显示"}（8/2 早于起始日 8/6）');

      await db.close();
    });

    test('T8: 全天任务 8/2 起、每月 2 号，在 8/2 应正常显示', () async {
      final apis = createTestApis();
      final db = apis.db;
      final todayApi = DatabaseTaskTodayApi(
        db: db,
        tagApi: apis.tagApi,
        outboxApi: apis.outboxApi,
      );

      final task = Task(
        id: const Uuid().v4(),
        title: 'allday-2nd',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-02T00:00:00'),
        endAt: Jiffy.parse('2026-08-02T23:59:59'),
        isAllDay: true,
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [2],
        ),
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await apis.taskApi.create(task: task);
      await apis.taskApi.preGenerateTaskOccurrences(
        fromDate: Jiffy.parse('2026-08-02'),
      );

      final entities = await todayApi
          .getTaskEntities(date: Jiffy.parse('2026-08-02'))
          .first;

      expect(
        entities.any((e) => e.task.id == task.id),
        isTrue,
        reason: '全天任务不涉及时间偏移，8/2 当天应显示',
      );

      await db.close();
    });

    test('T9: 带时间的任务 8/2 起、每月 2 号，在 8/2 应正常显示', () async {
      final apis = createTestApis();
      final db = apis.db;
      final todayApi = DatabaseTaskTodayApi(
        db: db,
        tagApi: apis.tagApi,
        outboxApi: apis.outboxApi,
      );

      final task = Task(
        id: const Uuid().v4(),
        title: 'timed-2nd',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-02T10:00:00'),
        endAt: Jiffy.parse('2026-08-02T11:00:00'),
        isAllDay: false,
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [2],
        ),
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await apis.taskApi.create(task: task);
      await apis.taskApi.preGenerateTaskOccurrences(
        fromDate: Jiffy.parse('2026-08-02'),
      );

      final entities = await todayApi
          .getTaskEntities(date: Jiffy.parse('2026-08-02'))
          .first;

      expect(
        entities.any((e) => e.task.id == task.id),
        isTrue,
        reason: '任务起始日当天实例时间未被偏移，8/2 应显示',
      );

      await db.close();
    });

    test('T10: 带时间的每月任务，实例会错误地出现在前一天', () async {
      final apis = createTestApis();
      final db = apis.db;
      final todayApi = DatabaseTaskTodayApi(
        db: db,
        tagApi: apis.tagApi,
        outboxApi: apis.outboxApi,
      );

      // 8/6 10:00 创建的带时间任务，规则每月 2 号
      final task = Task(
        id: const Uuid().v4(),
        title: 'timed-monthly-2nd',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-06T10:00:00'),
        endAt: Jiffy.parse('2026-08-06T11:00:00'),
        isAllDay: false,
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [2],
        ),
        alarms: const [],
        createdAt: Jiffy.now(),
      );
      await apis.taskApi.create(task: task);
      await apis.taskApi.preGenerateTaskOccurrences(
        fromDate: Jiffy.parse('2026-08-06'),
      );

      final onSep2 = await todayApi
          .getTaskEntities(date: Jiffy.parse('2026-09-02'))
          .first;
      final onSep1 = await todayApi
          .getTaskEntities(date: Jiffy.parse('2026-09-01'))
          .first;

      final visibleOnSep2 = onSep2.any((e) => e.task.id == task.id);
      final visibleOnSep1 = onSep1.any((e) => e.task.id == task.id);
      print(
        'T10 现状：9/2（正确日期）${visibleOnSep2 ? "显示" : "不显示"}，'
        '9/1（前一天）${visibleOnSep1 ? "显示" : "不显示"}',
      );

      // 正确行为：9/2 显示、9/1 不显示
      expect(visibleOnSep2, isTrue, reason: '实例应出现在正确的日期 9/2');
      expect(visibleOnSep1, isFalse, reason: '实例不应偏移到前一天 9/1');

      await db.close();
    });

    test('T13: 【根因】每月规则混入 daysOfWeek 时，星期几不应再过滤', () {
      // 真实数据库中「每月 8 日」保存的规则：
      // frequency=monthly, daysOfMonth=[8], daysOfWeek=[Thursday(4)]
      // daysOfWeek 是创建日（周四 8/6）的 UI 默认值残留
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        daysOfMonth: const [8],
        daysOfWeek: [RecurrenceDayOfWeek.day(Weekday.thursday)],
      );

      // 2026-08-08 是周六、2026-09-08 是周二、2026-10-08 是周四
      final occurrences = RecurrenceRuleCalculator.generateOccurrences(
        rule: rule,
        startDate: Jiffy.parse('2026-08-06'),
        rangeStart: Jiffy.parse('2026-08-06'),
        rangeEnd: Jiffy.parse('2026-11-06'),
      );

      final dates = occurrences
          .map((j) => '${j.year}-${j.month}-${j.date}')
          .toList();
      print('T11 生成的实例: $dates');

      // 期望：每月 8 号都应有实例（daysOfMonth 优先，星期几不参与过滤）
      expect(
        dates,
        containsAll(['2026-8-8', '2026-9-8', '2026-10-8']),
        reason: '每月 8 日的任务不应要求 8 号恰好是星期四',
      );
    });

    test('T5: 同一天 ensureSoftDeleteOccurrence 调用两次不应崩溃', () async {
      final apis = createTestApis();
      final db = apis.db;
      final delayApi = DatabaseTaskDelayApi(db: db, tagApi: apis.tagApi);

      final date = Jiffy.parse('2026-08-06').startOf(Unit.day);
      final task = Task(
        id: const Uuid().v4(),
        title: 'recurring',
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: Jiffy.parse('2026-08-01T10:00:00'),
        isAllDay: false,
        alarms: const [],
        createdAt: Jiffy.now(),
      );

      // 第一次：无 occurrence 行 → 插入已删除占位行（模拟同步首次到达）
      await delayApi.ensureSoftDeleteOccurrence(
        taskId: task.id,
        occurrenceAt: date,
        task: task,
      );
      // 第二次：占位行已存在且已删除（模拟同步再次到达同一分离实例）
      await delayApi.ensureSoftDeleteOccurrence(
        taskId: task.id,
        occurrenceAt: date,
        task: task,
      );

      final occurrences = await db.select(db.taskOccurrences).get();
      expect(occurrences, hasLength(1));

      await db.close();
    });
  });
}
