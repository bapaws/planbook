package com.bapaws.planbook.widget

import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

/**
 * 基于 SQLite 的 Widget 数据库管理类
 * 对应 iOS 端 WidgetDatabase.swift
 */
class WidgetDatabase private constructor(context: Context) {

    private val appContext: Context = context.applicationContext
    private val db: SQLiteDatabase

    init {
        // Flutter 的 path_provider 在 Android 上 getApplicationDocumentsDirectory() 实际返回的是
        // context.getDir("flutter", MODE_PRIVATE)，对应物理路径 /data/data/<pkg>/app_flutter/
        // 注意：不是 context.filesDir（即 /data/data/<pkg>/files/）
        val docsDir = appContext.getDir("flutter", Context.MODE_PRIVATE)
        val dbFile = File(docsDir, "planbook.sqlite")
        if (!dbFile.exists()) {
            throw IllegalStateException("Database file not found: ${dbFile.path}. Please open the app first.")
        }
        // App 端使用 PRAGMA journal_mode=WAL，需要可写权限才能读取 WAL 中的最新数据
        db = SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READWRITE)
        db.enableWriteAheadLogging()
    }

    companion object {
        @Volatile
        private var instance: WidgetDatabase? = null
        @Volatile
        private var initFailed = false

        fun getInstance(context: Context): WidgetDatabase? {
            if (initFailed) return null
            return instance ?: synchronized(this) {
                instance ?: try {
                    WidgetDatabase(context.applicationContext).also { instance = it }
                } catch (_: Exception) {
                    initFailed = true
                    null
                }
            }
        }
    }

    /** 查询四象限任务（支持 today / inbox / overdue 三种过滤模式） */
    fun fetchQuadrantTasks(filterMode: TaskFilterMode = TaskFilterMode.TODAY): List<QuadrantGroup> {
        val priorities = listOf(TaskPriority.HIGH, TaskPriority.MEDIUM, TaskPriority.LOW, TaskPriority.NONE)
        return priorities.map { priority ->
            val tasks = fetchTasks(priority, filterMode, 10)
            QuadrantGroup(priority, tasks)
        }
    }

    /** 查询指定优先级的任务 */
    fun fetchTasks(priority: TaskPriority, filterMode: TaskFilterMode = TaskFilterMode.TODAY, limit: Int = 5): List<QuadrantTask> {
        val userId = WidgetSettings.getCurrentUserId(appContext)
        val sql = sqlForFilterMode(filterMode, priority, userId, limit)
        val args = mutableListOf(priority.rawValue)
        if (userId != null) args.add(userId)
        args.add(limit.toString())
        val tasks = mutableListOf<QuadrantTask>()
        db.rawQuery(sql, args.toTypedArray()).use { cursor ->
            while (cursor.moveToNext()) {
                tasks.add(cursor.toQuadrantTask())
            }
        }
        return tasks
    }

    /** 读取单个任务当前在 DB 中的完成状态；不存在或读库失败返回 null */
    fun isTaskCompleted(taskId: String): Boolean? {
        val userId = WidgetSettings.getCurrentUserId(appContext)
        val userClause = if (userId == null) "AND t.user_id IS NULL" else "AND t.user_id = ?"
        val args = mutableListOf(taskId)
        if (userId != null) args.add(userId)
        return try {
            db.rawQuery(
                """
                SELECT 1
                FROM task_activities ta
                JOIN tasks t ON t.id = ta.task_id
                WHERE ta.task_id = ?
                  AND ta.deleted_at IS NULL
                  $userClause
                LIMIT 1
                """.trimIndent(),
                args.toTypedArray()
            ).use { cursor ->
                cursor.moveToFirst()
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * 标记任务完成 / 撤销完成。
     *
     * 完成或撤销后，会按 [WidgetSettings.getTaskAutoNoteType] 配置自动创建笔记
     * （和 Flutter 端 `TaskListBloc/_onNoteCreated` 行为对齐）：
     * - `none` / `edit`：不创建（小部件端无法弹出"编辑笔记"页，故 edit 不动作）
     * - `create` / `createAndEdit`：插入一条 notes 记录，并把任务的 task_tags 复制到 note_tags
     *
     * 笔记标题：完成 → "✅ {task.title}"；撤销 → "❌ {task.title}"
     */
    fun toggleTaskCompletion(taskId: String, context: Context? = null) {
        val nowIso = iso8601Now()
        val userId = WidgetSettings.getCurrentUserId(appContext)
        // 与 fetchTasks 一致：未登录走 IS NULL 分支，已登录走 user_id = ?
        val userClause = if (userId == null) "AND user_id IS NULL" else "AND user_id = ?"

        // 查询任务基本信息（用于自动笔记的标题、priority 等）
        var taskTitle: String? = null
        var taskPriorityRaw: String? = null
        var taskParentId: String? = null
        val taskLookupArgs = mutableListOf(taskId)
        if (userId != null) taskLookupArgs.add(userId)
        db.rawQuery(
            "SELECT title, priority, parent_id FROM tasks WHERE id = ? AND deleted_at IS NULL $userClause LIMIT 1",
            taskLookupArgs.toTypedArray()
        ).use { cursor ->
            if (cursor.moveToFirst()) {
                taskTitle = cursor.getString(cursor.getColumnIndexOrThrow("title"))
                val priorityIdx = cursor.getColumnIndexOrThrow("priority")
                taskPriorityRaw = if (cursor.isNull(priorityIdx)) null else cursor.getString(priorityIdx)
                val parentIdx = cursor.getColumnIndexOrThrow("parent_id")
                taskParentId = if (cursor.isNull(parentIdx)) null else cursor.getString(parentIdx)
            }
        }

        // 任务不存在（或不属于当前用户）：不写入任何 activity，避免越权改别的账户数据。
        if (taskTitle == null) return

        var didComplete = false

        db.beginTransaction()
        try {
            // 查询该任务当前的有效 activity（同样按 user_id 过滤）
            var activityId: String? = null
            var isCompleted = false
            val activityLookupArgs = mutableListOf(taskId)
            if (userId != null) activityLookupArgs.add(userId)
            db.rawQuery(
                """
                SELECT id, completed_at
                FROM task_activities
                WHERE task_id = ?
                  AND deleted_at IS NULL
                  $userClause
                LIMIT 1
                """.trimIndent(),
                activityLookupArgs.toTypedArray()
            ).use { cursor ->
                if (cursor.moveToFirst()) {
                    activityId = cursor.getString(cursor.getColumnIndexOrThrow("id"))
                    isCompleted = !cursor.isNull(cursor.getColumnIndexOrThrow("completed_at"))
                }
            }

            if (isCompleted && activityId != null) {
                // 撤销完成：软删除 activity
                db.execSQL(
                    """
                    UPDATE task_activities
                    SET deleted_at = ?, updated_at = ?
                    WHERE id = ?
                    """.trimIndent(),
                    arrayOf(nowIso, nowIso, activityId)
                )
                didComplete = false
            } else {
                // 标记完成：插入新 activity（带上当前用户 id，与 Flutter 端 TasksRepository.completeTask 一致）
                val newId = newUuid()
                db.execSQL(
                    """
                    INSERT INTO task_activities (id, task_id, user_id, completed_at, created_at)
                    VALUES (?, ?, ?, ?, ?)
                    """.trimIndent(),
                    arrayOf(newId, taskId, userId, nowIso, nowIso)
                )
                didComplete = true
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }

        // 根据设置创建自动笔记（与 Flutter 端 _onNoteCreated 行为一致）。
        if (context != null && taskTitle != null) {
            val type = WidgetSettings.getTaskAutoNoteType(
                context,
                taskPriorityRaw = taskPriorityRaw,
                isSubtask = taskParentId != null,
            )
            if (type.shouldCreate) {
                createAutoNoteForTask(
                    taskId = taskId,
                    taskTitle = taskTitle!!,
                    isCompleting = didComplete,
                    nowIso = nowIso,
                    userId = userId,
                )
            }
        }
    }

    /**
     * 完成/撤销任务时插入一条与任务关联的 note，并复制 task_tags 到 note_tags。
     */
    private fun createAutoNoteForTask(
        taskId: String,
        taskTitle: String,
        isCompleting: Boolean,
        nowIso: String,
        userId: String?,
    ) {
        val noteId = newUuid()
        val emoji = if (isCompleting) "✅" else "❌"
        val noteTitle = "$emoji $taskTitle"

        db.beginTransaction()
        try {
            // 笔记本身按当前用户写入，避免出现"未登录创建、登录后看不到"的反常状况
            db.execSQL(
                """
                INSERT INTO notes (id, title, task_id, user_id, images, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """.trimIndent(),
                arrayOf(noteId, noteTitle, taskId, userId, "[]", nowIso)
            )

            // 把 task_tags 整体复制到 note_tags（包括 linked_tag_id 父级关联）；
            // 这里读取的 task_tags 也按当前用户过滤，避免把别的账号的标签关联过来
            val tagLookupArgs = mutableListOf(taskId)
            val tagUserClause = if (userId == null) "AND user_id IS NULL" else "AND user_id = ?"
            if (userId != null) tagLookupArgs.add(userId)
            db.rawQuery(
                """
                SELECT tag_id, linked_tag_id, user_id
                FROM task_tags
                WHERE task_id = ? AND deleted_at IS NULL $tagUserClause
                """.trimIndent(),
                tagLookupArgs.toTypedArray()
            ).use { cursor ->
                while (cursor.moveToNext()) {
                    val tagId = cursor.getString(cursor.getColumnIndexOrThrow("tag_id"))
                    val linkedTagIdx = cursor.getColumnIndexOrThrow("linked_tag_id")
                    val linkedTagId = if (cursor.isNull(linkedTagIdx)) null else cursor.getString(linkedTagIdx)
                    val userIdIdx = cursor.getColumnIndexOrThrow("user_id")
                    val rowUserId = if (cursor.isNull(userIdIdx)) null else cursor.getString(userIdIdx)

                    db.execSQL(
                        """
                        INSERT INTO note_tags (id, note_id, tag_id, linked_tag_id, user_id, created_at)
                        VALUES (?, ?, ?, ?, ?, ?)
                        """.trimIndent(),
                        arrayOf(newUuid(), noteId, tagId, linkedTagId, rowUserId, nowIso)
                    )
                }
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    private fun newUuid(): String =
        UUID.randomUUID().toString()

    private fun sqlForFilterMode(filterMode: TaskFilterMode, priority: TaskPriority, userId: String?, limit: Int): String {
        // 与 Flutter 端 DatabaseTaskTodayApi / InboxApi / OverdueApi 一致：
        //   未登录 → 仅展示 user_id IS NULL 的任务
        //   已登录 → 仅展示 user_id = ? 的任务
        val userClause = if (userId == null) "AND t.user_id IS NULL" else "AND t.user_id = ?"
        return when (filterMode) {
            // 注意：所有时间字段都是 ISO8601 UTC 字符串（带 .999999Z 等小数秒）。
            // SQLite 的 datetime(x, 'localtime') 在遇到 .999999 时会向上进位到下一秒，
            // 例如 '2026-04-24T15:59:59.999999Z' 会被算成本地的下一天 00:00:00，
            // 导致全天任务（end_at = 当日 23:59:59.999999）被错误地归到第二天。
            // 这里用 substr(x, 1, 19) || 'Z' 截断小数秒后再做时区转换，避免进位。
            TaskFilterMode.TODAY -> """
                SELECT DISTINCT
                    t.id, t.title, t.priority, t.alarms,
                    ta.completed_at, ta.deleted_at AS activity_deleted_at
                FROM tasks t
                LEFT JOIN task_activities ta
                    ON ta.task_id = t.id AND ta.deleted_at IS NULL
                LEFT JOIN task_occurrences toc
                    ON toc.task_id = t.id
                    AND date(datetime(substr(toc.occurrence_at, 1, 19) || 'Z', 'localtime')) = date('now', 'localtime')
                    AND toc.deleted_at IS NULL
                WHERE t.deleted_at IS NULL
                  AND t.parent_id IS NULL
                  AND COALESCE(t.priority, 'none') = ?
                  $userClause
                  AND (
                      (t.recurrence_rule IS NULL AND t.detached_from_task_id IS NULL AND date(datetime(substr(t.start_at, 1, 19) || 'Z', 'localtime')) = date('now', 'localtime'))
                      OR (t.recurrence_rule IS NULL AND t.detached_from_task_id IS NULL AND date(datetime(substr(t.due_at, 1, 19) || 'Z', 'localtime')) = date('now', 'localtime'))
                      OR (t.recurrence_rule IS NULL AND t.detached_from_task_id IS NULL AND date(datetime(substr(t.end_at, 1, 19) || 'Z', 'localtime')) = date('now', 'localtime'))
                      OR toc.occurrence_at IS NOT NULL
                      OR (t.detached_from_task_id IS NOT NULL AND date(datetime(substr(t.detached_recurrence_at, 1, 19) || 'Z', 'localtime')) = date('now', 'localtime'))
                  )
                ORDER BY t."order" ASC, t.created_at ASC
                LIMIT ?
            """.trimIndent()

            TaskFilterMode.INBOX -> """
                SELECT DISTINCT
                    t.id, t.title, t.priority, t.alarms,
                    ta.completed_at, ta.deleted_at AS activity_deleted_at
                FROM tasks t
                LEFT JOIN task_activities ta
                    ON ta.task_id = t.id AND ta.deleted_at IS NULL
                WHERE t.deleted_at IS NULL
                  AND t.parent_id IS NULL
                  AND COALESCE(t.priority, 'none') = ?
                  $userClause
                  AND t.due_at IS NULL
                  AND t.start_at IS NULL
                  AND t.end_at IS NULL
                ORDER BY t."order" ASC, t.created_at ASC
                LIMIT ?
            """.trimIndent()

            // 同 TODAY 的说明：使用 substr(x, 1, 19) || 'Z' 截断小数秒，
            // 避免 SQLite 的 'localtime' 修饰符把 .999999 进位到下一秒，
            // 否则全天任务的 end_at 会被错误判断为"未过期"。
            TaskFilterMode.OVERDUE -> """
                SELECT DISTINCT
                    t.id, t.title, t.priority, t.alarms,
                    ta.completed_at, ta.deleted_at AS activity_deleted_at
                FROM tasks t
                LEFT JOIN task_activities ta
                    ON ta.task_id = t.id AND ta.deleted_at IS NULL
                LEFT JOIN task_occurrences toc
                    ON toc.task_id = t.id
                    AND date(datetime(substr(toc.occurrence_at, 1, 19) || 'Z', 'localtime')) < date('now', 'localtime')
                    AND toc.deleted_at IS NULL
                WHERE t.deleted_at IS NULL
                  AND t.parent_id IS NULL
                  AND COALESCE(t.priority, 'none') = ?
                  $userClause
                  AND ta.id IS NULL
                  AND (
                      (
                          t.recurrence_rule IS NULL
                          AND t.detached_from_task_id IS NULL
                          AND (
                              (t.due_at IS NOT NULL AND date(datetime(substr(t.due_at, 1, 19) || 'Z', 'localtime')) < date('now', 'localtime'))
                              OR (t.end_at IS NOT NULL AND datetime(substr(t.end_at, 1, 19) || 'Z', 'localtime') < datetime('now', 'localtime'))
                          )
                      )
                      OR (
                          t.recurrence_rule IS NOT NULL
                          AND toc.occurrence_at IS NOT NULL
                      )
                      OR (
                          t.detached_from_task_id IS NOT NULL
                          AND t.detached_recurrence_at IS NOT NULL
                          AND date(datetime(substr(t.detached_recurrence_at, 1, 19) || 'Z', 'localtime')) < date('now', 'localtime')
                          AND (t.detached_reason IS NULL OR t.detached_reason != 'completed')
                      )
                  )
                ORDER BY t."order" ASC, t.created_at ASC
                LIMIT ?
            """.trimIndent()
        }
    }

    private fun Cursor.toQuadrantTask(): QuadrantTask {
        val id = getString(getColumnIndexOrThrow("id"))
        val title = getString(getColumnIndexOrThrow("title"))
        val priority = getString(getColumnIndexOrThrow("priority"))
        val completedAt = if (isNull(getColumnIndexOrThrow("completed_at"))) null else getString(getColumnIndexOrThrow("completed_at"))
        val activityDeletedAt = if (isNull(getColumnIndexOrThrow("activity_deleted_at"))) null else getString(getColumnIndexOrThrow("activity_deleted_at"))
        val alarms = if (isNull(getColumnIndexOrThrow("alarms"))) null else getString(getColumnIndexOrThrow("alarms"))

        val isCompleted = completedAt != null && activityDeletedAt == null
        val hasAlarm = alarms != null && alarms.isNotEmpty()

        return QuadrantTask(
            id = id,
            title = title,
            priority = TaskPriority.fromRawValue(priority),
            isCompleted = isCompleted,
            hasAlarm = hasAlarm
        )
    }

    private fun iso8601Now(): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        return formatter.format(Date())
    }
}
