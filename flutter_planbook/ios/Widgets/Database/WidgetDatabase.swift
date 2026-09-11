//
//  WidgetDatabase.swift
//  Widgets
//
//  基于 GRDB 读取 App Group 共享数据库
//  替代原有的 SQLite3 C API 实现
//

import Foundation
import GRDB

/// 基于 GRDB 的 Widget 数据库管理类
///
/// 职责：
/// - 管理 App Group 共享数据库的连接（WAL 模式）
/// - 提供四象限任务查询（today / inbox / overdue）
/// - 提供单个任务完成状态的只读查询，供 widget AppIntent 计算翻转目标
///
/// 注意：widget 进程**只读** DB，所有写入（完成/取消/笔记/Supabase 同步）
/// 全部由 Flutter 端在主 App 中完成。
@available(iOS 16.0, *)
final class WidgetDatabase {
    static let shared = WidgetDatabase()

    private let dbQueue: DatabaseQueue

    private init() {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: kAppGroupId)?
            .appendingPathComponent(kDBName)
        else {
            fatalError("[Widget] Failed to get App Group container URL")
        }

        var config = Configuration()
        config.journalMode = .wal

        do {
            dbQueue = try DatabaseQueue(path: containerURL.path, configuration: config)
        } catch {
            fatalError("[Widget] Failed to open database: \(error)")
        }
    }

    // MARK: - Queries

    /// 查询四象限任务（支持 today / inbox / overdue 三种过滤模式）
    /// 内部按优先级分别查询，每个优先级最多 10 条
    func fetchQuadrantTasks(filterMode: TaskFilterMode = .today) -> [QuadrantGroup] {
        let priorities: [TaskPriority] = [.high, .medium, .low, .none]
        return priorities.map { priority in
            let tasks = fetchTasks(forPriority: priority, filterMode: filterMode, limit: 10)
            return QuadrantGroup(priority: priority, tasks: tasks)
        }
    }

    /// 查询指定优先级的任务
    func fetchTasks(forPriority priority: TaskPriority, filterMode: TaskFilterMode = .today, limit: Int = 5) -> [QuadrantTask] {
        let userId = WidgetSettings.currentUserId
        let sql = sqlForFilterMode(filterMode, priority: priority, userId: userId, limit: limit)

        var args: [DatabaseValueConvertible] = [priority.rawValue]
        if let userId {
            args.append(userId)
        }
        args.append(limit)

        do {
            return try dbQueue.read { db in
                let tasks = try QuadrantTask.fetchAll(db, sql: sql, arguments: StatementArguments(args))
                return collapseQuadrantTasks(tasks)
            }
        } catch {
            print("[Widget] Failed to fetch tasks for priority \(priority): \(error)")
            return []
        }
    }

    /// 读取单个任务当前在 DB 中的完成状态。
    ///
    /// 任务不存在或读库失败返回 `nil`；CompleteTaskIntent 在没有 pending
    /// 缓存时用它作为权威来源，计算翻转目标。
    /// 通过 join `tasks` 按当前登录用户过滤，避免读到其他账号残留的 activity。
    func isTaskCompleted(taskId: String, occurrenceAt: String? = nil) -> Bool? {
        let userId = WidgetSettings.currentUserId
        let userClause = userId == nil ? "AND t.user_id IS NULL" : "AND t.user_id = ?"
        let occurrence = occurrenceAt.flatMap { $0.isEmpty ? nil : $0 }
        // occurrenceAt 为空表示非重复任务，只匹配 occurrence_at IS NULL；
        // 不能省略条件，否则重复任务任意一天完成都会被当成整组已完成。
        let occurrenceClause: String
        if occurrence == nil {
            occurrenceClause = "AND ta.occurrence_at IS NULL"
        } else {
            occurrenceClause = "AND ta.occurrence_at = ?"
        }

        var args: [DatabaseValueConvertible] = [taskId]
        if let userId {
            args.append(userId)
        }
        if let occurrence {
            args.append(occurrence)
        }

        do {
            return try dbQueue.read { db in
                let row = try Row.fetchOne(
                    db,
                    sql: """
                    SELECT 1
                    FROM task_activities ta
                    JOIN tasks t ON t.id = ta.task_id
                    WHERE ta.task_id = ?
                      AND ta.deleted_at IS NULL
                      \(userClause)
                      \(occurrenceClause)
                    LIMIT 1
                    """,
                    arguments: StatementArguments(args)
                )
                return row != nil
            }
        } catch {
            print("[Widget] Failed to read completion for task \(taskId): \(error)")
            return nil
        }
    }

    /// 今天有起止时间的非全天顶层任务（对齐 App 时间块过滤）。
    func fetchTimeBlockTasks() -> [TimeBlockTask] {
        let userId = WidgetSettings.currentUserId
        let userClause = userId == nil ? "AND t.user_id IS NULL" : "AND t.user_id = ?"
        var args: [DatabaseValueConvertible] = []
        if let userId {
            args.append(userId)
            args.append(userId)
            args.append(userId)
        }

        let sql = """
        SELECT DISTINCT
            t.id, t.title, t.priority,
            t.start_at, t.end_at,
            NULL AS occurrence_at,
            CASE WHEN EXISTS (
                SELECT 1 FROM task_activities ta
                WHERE ta.task_id = t.id
                  AND ta.deleted_at IS NULL
                  AND ta.completed_at IS NOT NULL
                  AND ta.occurrence_at IS NULL
            ) THEN '1' END AS completed_at,
            NULL AS activity_deleted_at
        FROM tasks t
        WHERE t.deleted_at IS NULL
          AND t.parent_id IS NULL
          AND COALESCE(t.is_all_day, 0) = 0
          AND t.start_at IS NOT NULL
          AND t.recurrence_rule IS NULL
          AND t.detached_from_task_id IS NULL
          \(userClause)
          AND datetime(substr(t.start_at, 1, 19) || 'Z', 'localtime')
              < datetime('now', 'localtime', 'start of day', '+1 day')
          AND (
              (t.end_at IS NOT NULL
               AND datetime(substr(t.end_at, 1, 19) || 'Z', 'localtime')
                   >= datetime('now', 'localtime', 'start of day'))
              OR (t.end_at IS NULL
                  AND date(datetime(substr(t.start_at, 1, 19) || 'Z', 'localtime'))
                      = date('now', 'localtime'))
          )
        UNION ALL
        SELECT DISTINCT
            t.id, t.title, t.priority,
            t.start_at, t.end_at,
            NULL AS occurrence_at,
            CASE WHEN EXISTS (
                SELECT 1 FROM task_activities ta
                WHERE ta.task_id = t.id
                  AND ta.deleted_at IS NULL
                  AND ta.completed_at IS NOT NULL
                  AND ta.occurrence_at IS NULL
            ) THEN '1' END AS completed_at,
            NULL AS activity_deleted_at
        FROM tasks t
        WHERE t.deleted_at IS NULL
          AND t.parent_id IS NULL
          AND COALESCE(t.is_all_day, 0) = 0
          AND t.start_at IS NOT NULL
          AND t.detached_from_task_id IS NOT NULL
          AND t.detached_recurrence_at IS NOT NULL
          \(userClause)
          AND date(datetime(substr(t.detached_recurrence_at, 1, 19) || 'Z', 'localtime'))
              = date('now', 'localtime')
        UNION ALL
        SELECT DISTINCT
            t.id, t.title, t.priority,
            COALESCE(toc.start_at, t.start_at) AS start_at,
            COALESCE(toc.end_at, t.end_at) AS end_at,
            toc.occurrence_at,
            CASE WHEN EXISTS (
                SELECT 1 FROM task_activities ta
                WHERE ta.task_id = t.id
                  AND ta.deleted_at IS NULL
                  AND ta.completed_at IS NOT NULL
                  AND ta.occurrence_at = toc.occurrence_at
            ) THEN '1' END AS completed_at,
            NULL AS activity_deleted_at
        FROM tasks t
        INNER JOIN task_occurrences toc
            ON toc.task_id = t.id
            AND toc.deleted_at IS NULL
            AND (
                (
                    toc.start_at IS NOT NULL AND toc.end_at IS NOT NULL
                    AND datetime(substr(toc.start_at, 1, 19) || 'Z', 'localtime')
                        < datetime('now', 'localtime', 'start of day', '+1 day')
                    AND datetime(substr(toc.end_at, 1, 19) || 'Z', 'localtime')
                        >= datetime('now', 'localtime', 'start of day')
                )
                OR (
                    toc.due_at IS NOT NULL
                    AND date(datetime(substr(toc.due_at, 1, 19) || 'Z', 'localtime'))
                        = date('now', 'localtime')
                )
                OR (
                    toc.start_at IS NULL
                    AND date(datetime(substr(toc.occurrence_at, 1, 19) || 'Z', 'localtime'))
                        = date('now', 'localtime')
                )
            )
        WHERE t.deleted_at IS NULL
          AND t.parent_id IS NULL
          AND t.recurrence_rule IS NOT NULL
          AND t.detached_from_task_id IS NULL
          AND COALESCE(t.is_all_day, 0) = 0
          AND COALESCE(toc.start_at, t.start_at) IS NOT NULL
          \(userClause)
        """

        do {
            return try dbQueue.read { db in
                let tasks = try TimeBlockTask.fetchAll(db, sql: sql, arguments: StatementArguments(args))
                var seenTaskOccurrences = Set<String>()
                return tasks.filter { seenTaskOccurrences.insert($0.id).inserted }
            }
        } catch {
            print("[Widget] Failed to fetch time block tasks: \(error)")
            return []
        }
    }

    // MARK: - Private Helpers

    /// ISO8601 UTC 文本转本地日历日，截断小数秒避免 .999999 进位到下一天。
    private func sqlLocalDate(_ column: String) -> String {
        "date(datetime(substr(\(column), 1, 19) || 'Z', 'localtime'))"
    }

    private func sqlLocalDateTime(_ column: String) -> String {
        "datetime(substr(\(column), 1, 19) || 'Z', 'localtime')"
    }

    /// 重复任务实例是否落在「今天」，对齐 DatabaseTaskTodayApi 的 due/start-end 窗口。
    private func sqlOccurrenceIsToday(_ alias: String = "toc") -> String {
        """
        (
            (\(alias).due_at IS NOT NULL
             AND \(sqlLocalDate("\(alias).due_at")) = date('now', 'localtime'))
            OR (
                \(alias).start_at IS NOT NULL AND \(alias).end_at IS NOT NULL
                AND \(sqlLocalDateTime("\(alias).start_at"))
                    < datetime('now', 'localtime', 'start of day', '+1 day')
                AND \(sqlLocalDateTime("\(alias).end_at"))
                    >= datetime('now', 'localtime', 'start of day')
            )
            OR (
                \(alias).due_at IS NULL AND \(alias).start_at IS NULL
                AND \(sqlLocalDate("\(alias).occurrence_at")) = date('now', 'localtime')
            )
        )
        """
    }

    /// 重复任务实例是否已逾期，对齐 DatabaseTaskOverdueApi。
    private func sqlOccurrenceIsOverdue(_ alias: String = "toc") -> String {
        """
        (
            (\(alias).end_at IS NOT NULL
             AND \(sqlLocalDateTime("\(alias).end_at")) < datetime('now', 'localtime'))
            OR (
                \(alias).end_at IS NULL AND \(alias).due_at IS NOT NULL
                AND \(sqlLocalDate("\(alias).due_at")) < date('now', 'localtime')
            )
            OR (
                \(alias).end_at IS NULL AND \(alias).due_at IS NULL
                AND \(sqlLocalDate("\(alias).occurrence_at")) < date('now', 'localtime')
            )
        )
        """
    }

    /// 同一任务只保留一条：未完成优先，避免重复实例把象限刷满。
    private func collapseQuadrantTasks(_ tasks: [QuadrantTask]) -> [QuadrantTask] {
        var seen = Set<String>()
        return tasks
            .sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted {
                    return !lhs.isCompleted
                }
                return false
            }
            .filter { seen.insert($0.id).inserted }
    }

    private func sqlForFilterMode(_ filterMode: TaskFilterMode, priority: TaskPriority, userId: String?, limit: Int) -> String {
        // 与 Flutter 端 DatabaseTaskTodayApi / InboxApi / OverdueApi 一致：
        //   未登录 → 仅展示 user_id IS NULL 的任务
        //   已登录 → 仅展示 user_id = ? 的任务
        let userClause = userId == nil ? "AND t.user_id IS NULL" : "AND t.user_id = ?"
        let completedByOccurrence = """
            CASE WHEN EXISTS (
                SELECT 1 FROM task_activities ta
                WHERE ta.task_id = s.id
                  AND ta.deleted_at IS NULL
                  AND ta.completed_at IS NOT NULL
                  AND ta.occurrence_at = toc.occurrence_at
            ) THEN '1' END
        """
        let completedWithoutOccurrence = """
            CASE WHEN EXISTS (
                SELECT 1 FROM task_activities ta
                WHERE ta.task_id = s.id
                  AND ta.deleted_at IS NULL
                  AND ta.completed_at IS NOT NULL
                  AND ta.occurrence_at IS NULL
            ) THEN '1' END
        """
        let scopedCte = """
            scoped AS (
                SELECT * FROM tasks t
                WHERE t.deleted_at IS NULL
                  AND t.parent_id IS NULL
                  AND COALESCE(t.priority, 'none') = ?
                  \(userClause)
            )
        """
        switch filterMode {
        case .today:
            return """
            WITH \(scopedCte)
            SELECT
                s.id, s.title, s.priority, s.alarms,
                NULL AS occurrence_at,
                \(completedWithoutOccurrence) AS completed_at,
                NULL AS activity_deleted_at,
                s."order" AS task_order, s.created_at AS task_created
            FROM scoped s
            WHERE s.recurrence_rule IS NULL
              AND s.detached_from_task_id IS NULL
              AND (
                  (s.start_at IS NOT NULL
                   AND \(sqlLocalDateTime("s.start_at"))
                       < datetime('now', 'localtime', 'start of day', '+1 day')
                   AND (
                       (s.end_at IS NOT NULL
                        AND \(sqlLocalDateTime("s.end_at"))
                            >= datetime('now', 'localtime', 'start of day'))
                       OR (s.end_at IS NULL
                           AND \(sqlLocalDate("s.start_at")) = date('now', 'localtime'))
                   ))
                  OR (s.due_at IS NOT NULL
                      AND \(sqlLocalDate("s.due_at")) = date('now', 'localtime'))
              )
            UNION ALL
            SELECT
                s.id, s.title, s.priority, s.alarms,
                NULL AS occurrence_at,
                \(completedWithoutOccurrence) AS completed_at,
                NULL AS activity_deleted_at,
                s."order" AS task_order, s.created_at AS task_created
            FROM scoped s
            WHERE s.detached_from_task_id IS NOT NULL
              AND s.detached_recurrence_at IS NOT NULL
              AND \(sqlLocalDate("s.detached_recurrence_at")) = date('now', 'localtime')
            UNION ALL
            SELECT
                s.id, s.title, s.priority, s.alarms,
                toc.occurrence_at,
                \(completedByOccurrence) AS completed_at,
                NULL AS activity_deleted_at,
                s."order" AS task_order, s.created_at AS task_created
            FROM scoped s
            INNER JOIN task_occurrences toc
                ON toc.task_id = s.id
                AND toc.deleted_at IS NULL
                AND \(sqlOccurrenceIsToday())
            WHERE s.recurrence_rule IS NOT NULL
              AND s.detached_from_task_id IS NULL
            ORDER BY task_order ASC, task_created ASC
            LIMIT ?
            """
        case .inbox:
            return """
            SELECT DISTINCT
                t.id, t.title, t.priority, t.alarms,
                NULL AS occurrence_at,
                CASE WHEN EXISTS (
                    SELECT 1 FROM task_activities ta
                    WHERE ta.task_id = t.id
                      AND ta.deleted_at IS NULL
                      AND ta.completed_at IS NOT NULL
                      AND ta.occurrence_at IS NULL
                ) THEN '1' END AS completed_at,
                NULL AS activity_deleted_at
            FROM tasks t
            WHERE t.deleted_at IS NULL
              AND t.parent_id IS NULL
              AND COALESCE(t.priority, 'none') = ?
              \(userClause)
              AND t.due_at IS NULL
              AND t.start_at IS NULL
              AND t.end_at IS NULL
            ORDER BY t."order" ASC, t.created_at ASC
            LIMIT ?
            """
        case .overdue:
            return """
            WITH \(scopedCte)
            SELECT
                s.id, s.title, s.priority, s.alarms,
                NULL AS occurrence_at,
                NULL AS completed_at,
                NULL AS activity_deleted_at,
                s."order" AS task_order, s.created_at AS task_created
            FROM scoped s
            WHERE s.recurrence_rule IS NULL
              AND s.detached_from_task_id IS NULL
              AND (
                  (s.due_at IS NOT NULL AND \(sqlLocalDate("s.due_at")) < date('now', 'localtime'))
                  OR (s.end_at IS NOT NULL AND \(sqlLocalDateTime("s.end_at")) < datetime('now', 'localtime'))
              )
              AND NOT EXISTS (
                  SELECT 1 FROM task_activities ta
                  WHERE ta.task_id = s.id
                    AND ta.deleted_at IS NULL
                    AND ta.completed_at IS NOT NULL
                    AND ta.occurrence_at IS NULL
              )
            UNION ALL
            SELECT
                s.id, s.title, s.priority, s.alarms,
                NULL AS occurrence_at,
                NULL AS completed_at,
                NULL AS activity_deleted_at,
                s."order" AS task_order, s.created_at AS task_created
            FROM scoped s
            WHERE s.detached_from_task_id IS NOT NULL
              AND s.detached_recurrence_at IS NOT NULL
              AND \(sqlLocalDate("s.detached_recurrence_at")) < date('now', 'localtime')
              AND (s.detached_reason IS NULL OR s.detached_reason != 'completed')
              AND NOT EXISTS (
                  SELECT 1 FROM task_activities ta
                  WHERE ta.task_id = s.id
                    AND ta.deleted_at IS NULL
                    AND ta.completed_at IS NOT NULL
                    AND ta.occurrence_at IS NULL
              )
            UNION ALL
            SELECT
                s.id, s.title, s.priority, s.alarms,
                toc.occurrence_at,
                NULL AS completed_at,
                NULL AS activity_deleted_at,
                s."order" AS task_order, s.created_at AS task_created
            FROM scoped s
            INNER JOIN task_occurrences toc
                ON toc.task_id = s.id
                AND toc.deleted_at IS NULL
                AND \(sqlOccurrenceIsOverdue())
            WHERE s.recurrence_rule IS NOT NULL
              AND s.detached_from_task_id IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM task_activities ta
                  WHERE ta.task_id = s.id
                    AND ta.deleted_at IS NULL
                    AND ta.completed_at IS NOT NULL
                    AND ta.occurrence_at = toc.occurrence_at
              )
            ORDER BY task_order ASC, task_created ASC
            LIMIT ?
            """
        }
    }

    private func defaultQuadrantGroups() -> [QuadrantGroup] {
        TaskPriority.allCases.map { QuadrantGroup(priority: $0, tasks: []) }
    }
}
