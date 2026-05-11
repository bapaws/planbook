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
                try QuadrantTask.fetchAll(db, sql: sql, arguments: StatementArguments(args))
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
    func isTaskCompleted(taskId: String) -> Bool? {
        let userId = WidgetSettings.currentUserId
        let userClause = userId == nil ? "AND t.user_id IS NULL" : "AND t.user_id = ?"

        var args: [DatabaseValueConvertible] = [taskId]
        if let userId {
            args.append(userId)
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

    // MARK: - Private Helpers

    private func sqlForFilterMode(_ filterMode: TaskFilterMode, priority: TaskPriority, userId: String?, limit: Int) -> String {
        // 与 Flutter 端 DatabaseTaskTodayApi / InboxApi / OverdueApi 一致：
        //   未登录 → 仅展示 user_id IS NULL 的任务
        //   已登录 → 仅展示 user_id = ? 的任务
        let userClause = userId == nil ? "AND t.user_id IS NULL" : "AND t.user_id = ?"
        switch filterMode {
        case .today:
            return """
            SELECT DISTINCT
                t.id, t.title, t.priority, t.alarms,
                ta.completed_at, ta.deleted_at AS activity_deleted_at
            FROM tasks t
            LEFT JOIN task_activities ta
                ON ta.task_id = t.id AND ta.deleted_at IS NULL
            LEFT JOIN task_occurrences toc
                ON toc.task_id = t.id
                AND date(datetime(toc.occurrence_at, 'localtime')) = date('now', 'localtime')
                AND toc.deleted_at IS NULL
            WHERE t.deleted_at IS NULL
              AND t.parent_id IS NULL
              AND COALESCE(t.priority, 'none') = ?
              \(userClause)
              AND (
                  (t.recurrence_rule IS NULL AND t.detached_from_task_id IS NULL AND date(datetime(t.start_at, 'localtime')) = date('now', 'localtime'))
                  OR (t.recurrence_rule IS NULL AND t.detached_from_task_id IS NULL AND date(datetime(t.due_at, 'localtime')) = date('now', 'localtime'))
                  OR (t.recurrence_rule IS NULL AND t.detached_from_task_id IS NULL AND date(datetime(t.end_at, 'localtime')) = date('now', 'localtime'))
                  OR toc.occurrence_at IS NOT NULL
                  OR (t.detached_from_task_id IS NOT NULL AND date(datetime(t.detached_recurrence_at, 'localtime')) = date('now', 'localtime'))
              )
            ORDER BY t."order" ASC, t.created_at ASC
            LIMIT ?
            """
        case .inbox:
            return """
            SELECT DISTINCT
                t.id, t.title, t.priority, t.alarms,
                ta.completed_at, ta.deleted_at AS activity_deleted_at
            FROM tasks t
            LEFT JOIN task_activities ta
                ON ta.task_id = t.id AND ta.deleted_at IS NULL
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
            SELECT DISTINCT
                t.id, t.title, t.priority, t.alarms,
                ta.completed_at, ta.deleted_at AS activity_deleted_at
            FROM tasks t
            LEFT JOIN task_activities ta
                ON ta.task_id = t.id AND ta.deleted_at IS NULL
            LEFT JOIN task_occurrences toc
                ON toc.task_id = t.id
                AND date(datetime(toc.occurrence_at, 'localtime')) < date('now', 'localtime')
                AND toc.deleted_at IS NULL
            WHERE t.deleted_at IS NULL
              AND t.parent_id IS NULL
              AND COALESCE(t.priority, 'none') = ?
              \(userClause)
              AND ta.id IS NULL
              AND (
                  (
                      t.recurrence_rule IS NULL
                      AND t.detached_from_task_id IS NULL
                      AND (
                          (t.due_at IS NOT NULL AND date(datetime(t.due_at, 'localtime')) < date('now', 'localtime'))
                          OR (t.end_at IS NOT NULL AND datetime(t.end_at, 'localtime') < datetime('now', 'localtime'))
                      )
                  )
                  OR (
                      t.recurrence_rule IS NOT NULL
                      AND toc.occurrence_at IS NOT NULL
                  )
                  OR (
                      t.detached_from_task_id IS NOT NULL
                      AND t.detached_recurrence_at IS NOT NULL
                      AND date(datetime(t.detached_recurrence_at, 'localtime')) < date('now', 'localtime')
                      AND (t.detached_reason IS NULL OR t.detached_reason != 'completed')
                  )
              )
            ORDER BY t."order" ASC, t.created_at ASC
            LIMIT ?
            """
        }
    }

    private func defaultQuadrantGroups() -> [QuadrantGroup] {
        TaskPriority.allCases.map { QuadrantGroup(priority: $0, tasks: []) }
    }
}
