package com.bapaws.planbook.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.bapaws.planbook_widget.WidgetActionDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private const val TAG = "PlanbookWidgetClick"

/**
 * Widget 点击事件接收器
 *
 * "完成任务" 流程：
 *   1. 计算翻转后的目标状态（优先看 pending 缓存，防止连点；其次读 DB）；
 *   2. 把目标状态写入 pending map，立即刷新 widget → 用户看到即时 UI 反馈；
 *   3. 派发到 Flutter 端跑完整业务（Supabase 同步、自动笔记、提醒取消等）；
 *   4. Flutter 完成后清除 pending，再次刷新 widget → 读到权威 DB 状态。
 */
class WidgetClickReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive action=${intent.action}")
        when (intent.action) {
            ACTION_COMPLETE_TASK -> {
                val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
                val occurrenceAt = intent.getStringExtra(EXTRA_OCCURRENCE_AT)
                val pending = goAsync()
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        // 1. 计算翻转后的目标状态——优先看 pending（防止用户连点时基于 stale DB 翻转），
                        //    其次回落到 DB 的真实状态；都拿不到就当作未完成。
                        val current = WidgetSettings.pendingCompletion(context, taskId)
                            ?: WidgetDatabase.getInstance(context)
                                ?.isTaskCompleted(taskId, occurrenceAt)
                            ?: false
                        val targetCompleted = !current

                        // 2. 写入 pending，让 widget 立刻刷新反馈。
                        WidgetSettings.setPendingCompletion(context, taskId, targetCompleted)
                        refreshAllTaskWidgets(context)

                        // 3. 派发到 Flutter 端跑完整业务。
                        val ok = WidgetActionDispatcher.completeTask(
                            context.applicationContext,
                            taskId,
                            occurrenceAt,
                        )

                        // 4. 清除 pending，再次刷新让 widget 读到权威 DB 状态。
                        WidgetSettings.clearPendingCompletion(context, taskId)
                        refreshAllTaskWidgets(context)

                        if (!ok) {
                            Log.w(TAG, "Flutter dispatch failed, widget will show stale state until next refresh. id=$taskId")
                        }
                        Log.d(TAG, "Task completed: $taskId (flutter=$ok)")
                    } catch (e: Exception) {
                        Log.e(TAG, "Complete task error", e)
                        // 异常时也要清掉 pending，避免 widget 永远停留在乐观状态。
                        WidgetSettings.clearPendingCompletion(context, taskId)
                        refreshAllTaskWidgets(context)
                    } finally {
                        pending.finish()
                    }
                }
            }
            ACTION_SWITCH_QUADRANT -> {
                val priorityRaw = intent.getStringExtra(EXTRA_PRIORITY) ?: return
                val priority = TaskPriority.fromRawValue(priorityRaw)
                WidgetSettings.setSelectedPriority(context, priority)
                refreshQuadrantSmallWidgets(context)
                Log.d(TAG, "Switched to: $priorityRaw")
            }
        }
    }

    companion object {
        const val ACTION_COMPLETE_TASK = "com.bapaws.planbook.widget.COMPLETE_TASK"
        const val ACTION_SWITCH_QUADRANT = "com.bapaws.planbook.widget.SWITCH_QUADRANT"

        const val EXTRA_TASK_ID = "task_id"
        const val EXTRA_OCCURRENCE_AT = "occurrence_at"
        const val EXTRA_PRIORITY = "priority"
    }
}
