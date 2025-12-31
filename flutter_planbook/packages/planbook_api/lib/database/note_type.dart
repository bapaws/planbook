/// 笔记类型（用于区分不同用途的笔记）
///
/// 笔记可以是日常的日记记录，也可以是用于目标设定的记录。
enum NoteType {
  /// 日记 - 日常的日记记录
  journal,

  /// 每日目标 - 用于记录每天的目标
  dailyFocus,

  /// 每周目标 - 用于记录每周的目标
  weeklyFocus,

  /// 每月目标 - 用于记录每月的目标
  monthlyFocus;

  /// 从字符串创建（用于数据库反序列化）
  static NoteType? fromString(String? value) {
    if (value == null) return null;
    return NoteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteType.journal,
    );
  }

  /// 是否为目标类型
  bool get isGoal => this == dailyFocus || this == weeklyFocus || this == monthlyFocus;

  /// 是否为日记类型
  bool get isJournal => this == journal;
}
