/// 任务优先级（参照 EventKit 的 EKReminderPriority）
///
/// 优先级从高到低：none < low < medium < high
/// 同时支持四象限时间管理法的映射
enum TaskPriority {
  /// 无优先级（默认）
  none(4),

  /// 低优先级
  low(3),

  /// 中等优先级
  medium(2),

  /// 高优先级
  high(1);

  const TaskPriority(this.value);

  /// 优先级值（0-4，值越大优先级越高）
  final int value;

  /// 从整数值创建优先级
  static TaskPriority? fromValue(int? value) {
    if (value == null) return null;
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.none,
    );
  }

  /// 获取优先级排序值（用于排序，值越大优先级越高）
  int get sortValue => value;

  /// 是否为高优先级（high 或 medium）
  bool get isHighPriority =>
      this == TaskPriority.high || this == TaskPriority.medium;

  /// 是否为低优先级（low 或 none）
  bool get isLowPriority =>
      this == TaskPriority.low || this == TaskPriority.none;

  /// 四象限分类（基于优先级映射）
  ///
  /// 映射规则：
  /// - High → 第一象限（重要且紧急）
  /// - Medium → 第二象限（重要不紧急）
  /// - Low → 第三象限（紧急但不重要）
  /// - None → 第四象限（不重要不紧急）
  Quadrant get quadrant {
    switch (this) {
      case TaskPriority.high:
        return Quadrant.importantUrgent;
      case TaskPriority.medium:
        return Quadrant.importantNotUrgent;
      case TaskPriority.low:
        return Quadrant.urgentUnimportant;
      case TaskPriority.none:
        return Quadrant.notUrgentUnimportant;
    }
  }

  /// 是否为重要任务（第一、二象限）
  bool get isImportant =>
      this == TaskPriority.high || this == TaskPriority.medium;

  /// 是否为紧急任务（第一、三象限）
  bool get isUrgent => this == TaskPriority.high || this == TaskPriority.low;
}

/// 四象限分类（基于 Eisenhower Matrix）
enum Quadrant {
  /// 第一象限：重要且紧急
  importantUrgent,

  /// 第二象限：重要不紧急
  importantNotUrgent,

  /// 第三象限：紧急但不重要
  urgentUnimportant,

  /// 第四象限：不重要不紧急
  notUrgentUnimportant;

  TaskPriority get priority => switch (this) {
    Quadrant.importantUrgent => TaskPriority.high,
    Quadrant.importantNotUrgent => TaskPriority.medium,
    Quadrant.urgentUnimportant => TaskPriority.low,
    Quadrant.notUrgentUnimportant => TaskPriority.none,
  };
}
