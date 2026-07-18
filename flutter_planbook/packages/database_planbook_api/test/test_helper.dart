import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:drift/native.dart';
import 'package:planbook_api/planbook_api.dart';

/// 创建测试用的内存数据库实例。
///
/// 每次调用返回一个全新的内存数据库，测试之间完全隔离。
/// 使用 [NativeDatabase.memory] 在后台 isolate 中运行 SQLite，
/// 与生产环境的行为一致。
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

/// 为测试数据库创建完整的 API 套件。
///
/// 返回的 tuple 包含：(db, outboxApi, tagApi, taskApi)
/// 所有 API 共享同一个数据库实例，确保事务一致性。
({
  AppDatabase db,
  OutboxApi outboxApi,
  DatabaseTagApi tagApi,
  DatabaseTaskApi taskApi,
})
createTestApis() {
  final db = createTestDatabase();
  final outboxApi = OutboxApi(db: db);
  final tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
  final taskApi = DatabaseTaskApi(db: db, tagApi: tagApi, outboxApi: outboxApi);
  return (db: db, outboxApi: outboxApi, tagApi: tagApi, taskApi: taskApi);
}
