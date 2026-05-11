package com.bapaws.planbook.widget

/**
 * Widget 数据模型
 * 对应 iOS 端 TaskRecord.swift
 */

enum class TaskPriority(val rawValue: String, val index: Int) {
    HIGH("high", 0),
    MEDIUM("medium", 1),
    LOW("low", 2),
    NONE("none", 3);

    companion object {
        fun fromRawValue(value: String?): TaskPriority {
            return entries.find { it.rawValue == value } ?: NONE
        }
    }

    fun quadrantTitle(): String = when (this) {
        HIGH -> "重要且紧急"
        MEDIUM -> "重要不紧急"
        LOW -> "紧急不重要"
        NONE -> "不重要不紧急"
    }

    val isImportant: Boolean
        get() = this == HIGH || this == MEDIUM

    val isUrgent: Boolean
        get() = this == HIGH || this == LOW
}

enum class TaskFilterMode(val rawValue: String) {
    TODAY("today"),
    INBOX("inbox"),
    OVERDUE("overdue");

    companion object {
        fun fromRawValue(value: String?): TaskFilterMode {
            return entries.find { it.rawValue == value } ?: TODAY
        }
    }

    val title: String
        get() = when (this) {
            TODAY -> "今天"
            INBOX -> "收集箱"
            OVERDUE -> "已逾期"
        }
}

data class QuadrantTask(
    val id: String,
    val title: String,
    val priority: TaskPriority,
    val isCompleted: Boolean,
    val hasAlarm: Boolean,
    val tagNames: List<String> = emptyList()
)

data class QuadrantGroup(
    val priority: TaskPriority,
    val tasks: List<QuadrantTask>
)
