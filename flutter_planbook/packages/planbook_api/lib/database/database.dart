import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_api/database/detached_reason.dart';
import 'package:planbook_api/database/event_alarm.dart';
import 'package:planbook_api/database/jiffy_converter.dart';
import 'package:planbook_api/database/list_converter.dart';
import 'package:planbook_api/database/recurrence_rule.dart';
import 'package:planbook_api/database/task_priority.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const _uuid = Uuid();

@DataClassName('Task')
class Tasks extends Table {
  // 基础字段
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get userId => text().nullable()();
  TextColumn get title => text()();

  // 层级关系
  // 父任务ID（用于子任务功能，指向父任务）
  TextColumn get parentId => text().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get layer => integer().withDefault(const Constant(0))();
  IntColumn get childCount => integer().withDefault(const Constant(0))();
  // 排序字段（用于子任务列表排序）
  IntColumn get order => integer().withDefault(const Constant(0))();

  // 任务时间
  // 开始和结束时间（用于 Event 类型）
  DateTimeColumn get startAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  DateTimeColumn get endAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  // 截止日期（用于 Reminder 类型）
  DateTimeColumn get dueAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  // 重复规则
  TextColumn get recurrenceRule =>
      text().map(const RecurrenceRuleConverter()).nullable()();

  // ========== 实例分离（Apple Calendar 风格）==========
  // 分离前的任务ID（如果是分离实例，记录分离前的原始重复任务ID）
  // 注意：可以通过 detachedFromTaskId != null 来判断是否为分离实例
  TextColumn get detachedFromTaskId => text().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.setNull,
  )();

  // 分离实例对应的原始重复日期（用于标识这个分离实例对应原始重复任务的哪个日期）
  // 例如：原始任务每周一重复，用户修改了 2024-01-15（周一）的实例
  // 那么这个分离实例的 detachedRecurrenceAt 就是 2024-01-15
  DateTimeColumn get detachedRecurrenceAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  // 分离原因（用于区分完成、跳过、修改等）
  TextColumn get detachedReason => textEnum<DetachedReason>().nullable()();

  // 提醒
  TextColumn get alarms =>
      text().map(const EventAlarmListConverter()).nullable()();

  // 优先级（四象限）
  TextColumn get priority => textEnum<TaskPriority>().nullable()();

  // 位置和备注
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();

  // 时区（可选，用于跨时区任务）
  TextColumn get timeZone => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().map(const JiffyConverter()).withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  DateTimeColumn get deletedAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Notes extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get userId => text().nullable()();

  // 标题和内容
  TextColumn get title => text()();
  TextColumn get content => text().nullable()();
  TextColumn get images =>
      text().map(const ListConverter<String>()).nullable()();

  TextColumn get taskId => text().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.setNull,
  )();

  DateTimeColumn get createdAt =>
      dateTime().map(const JiffyConverter()).withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  DateTimeColumn get deletedAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 标签表（支持多级标签，一级标签可作为分类，二级及以下作为标签）
class Tags extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  IntColumn get order => integer().withDefault(const Constant(0))();

  // 多级标签支持
  // 父标签ID（用于构建层级关系，null 表示一级标签/分类）
  TextColumn get parentId => text().nullable().references(
    Tags,
    #id,
    onDelete: KeyAction.cascade,
  )();
  // 层级深度（0 = 一级标签/分类，1 = 二级标签，以此类推）
  IntColumn get level => integer().withDefault(const Constant(0))();

  TextColumn get darkColorScheme =>
      text().map(const ColorSchemeConverter()).nullable()();
  TextColumn get lightColorScheme =>
      text().map(const ColorSchemeConverter()).nullable()();

  DateTimeColumn get createdAt =>
      dateTime().map(const JiffyConverter()).withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  DateTimeColumn get deletedAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class NoteTags extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get noteId => text().references(
    Notes,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get tagId => text().references(
    Tags,
    #id,
    onDelete: KeyAction.cascade,
  )();
  BoolColumn get isParent => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().map(const JiffyConverter()).withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  DateTimeColumn get deletedAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskTags extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get taskId => text().references(
    Tasks,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get tagId => text().references(
    Tags,
    #id,
    onDelete: KeyAction.cascade,
  )();
  BoolColumn get isParent => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().map(const JiffyConverter()).withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  DateTimeColumn get deletedAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 任务活动表（记录任务相关的操作，如完成、计时等）
@DataClassName('TaskActivity')
class TaskActivities extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get userId => text().nullable()();

  // 关联的任务
  TextColumn get taskId => text().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.setNull,
  )();

  // 任务完成时间
  DateTimeColumn get completedAt => dateTime()
      .map(const JiffyConverter())
      .nullable()
      .withDefault(currentDateAndTime)();

  // 活动类型（用于区分完成、跳过、修改等）
  // 可选：completed, skipped, modified 等
  TextColumn get activityType => text().nullable()();

  // 关联的实例日期（用于重复任务，标识该活动是针对哪个实例的）
  DateTimeColumn get occurrenceAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  // 计时信息
  // 计时开始时间（与 Task 中的 startAt 命名保持一致）
  DateTimeColumn get startAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  // 计时结束时间（与 Task 中的 endAt 命名保持一致）
  DateTimeColumn get endAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  // 持续时间（秒），用于方便查询和统计
  // 如果 startAt 和 endAt 都存在，可以通过计算得出
  IntColumn get duration => integer().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().map(const JiffyConverter()).withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  DateTimeColumn get deletedAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 任务实例表（用于存储重复任务的预生成实例，提高查询性能）
///
/// 对于有重复规则的任务，预先计算并存储未来一段时间内的所有实例。
/// 这样可以：
/// 1. 通过日期索引快速查询
/// 2. 避免每次查询时重复计算重复规则
/// 3. 支持高效的日期范围查询
@DataClassName('TaskOccurrence')
class TaskOccurrences extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  // 关联的原始任务
  TextColumn get taskId => text().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.cascade,
  )();

  // 实例日期（该任务实例应该执行的日期）
  DateTimeColumn get occurrenceAt => dateTime().map(const JiffyConverter())();

  // 实例的开始时间（如果任务有 startAt）
  DateTimeColumn get startAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  // 实例的结束时间（如果任务有 endAt）
  DateTimeColumn get endAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  // 实例的截止时间（如果任务有 dueAt）
  DateTimeColumn get dueAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  DateTimeColumn get createdAt =>
      dateTime().map(const JiffyConverter()).withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().map(const JiffyConverter()).nullable()();
  DateTimeColumn get deletedAt =>
      dateTime().map(const JiffyConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};

  // 创建索引以提高查询性能
  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, occurrenceAt}, // 同一任务的同一日期只能有一个实例
  ];
}

@DriftDatabase(
  tables: [
    Tasks,
    Notes,
    Tags,
    NoteTags,
    TaskTags,
    TaskActivities,
    TaskOccurrences,
  ],
)
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/getting-started/#open
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    // `driftDatabase` from `package:drift_flutter` stores the database in
    // `getApplicationDocumentsDirectory()`.
    // return driftDatabase(name: 'yummy');
    return LazyDatabase(() async {
      final file = await getDatabaseFile();

      // Also work around limitations on old Android versions
      if (Platform.isAndroid) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }

      // Make sqlite3 pick a more suitable location for temporary files - the
      // one from the system may be inaccessible due to sandboxing.
      final cachebase = (await getTemporaryDirectory()).path;
      // We can't access /tmp on Android, which sqlite3 would try by default.
      // Explicitly tell it about the correct temporary directory.
      sqlite3.tempDirectory = cachebase;

      return NativeDatabase.createInBackground(file);
    });
  }

  static Future<File> getDatabaseFile() async {
    String? path;
    if (Platform.isIOS) {
      final providerFoundation = PathProviderFoundation();
      path = await providerFoundation.getContainerPath(
        appGroupIdentifier: kAppGroupId,
      );
    }
    path ??= (await getApplicationDocumentsDirectory()).path;
    final file = File(p.join(path, 'habits.sqlite'));
    debugPrint('database file: $file');
    return file;
  }
}
