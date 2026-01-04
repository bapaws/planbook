/// 笔记类型（用于区分不同用途的笔记）
///
/// 笔记可以是日常的日记记录，也可以是用于目标设定的记录。
enum NoteType {
  /// 日记 - 日常的日记记录
  journal,

  /// 每日目标 - 用于记录每天的目标
  dailyFocus,
  dailySummary,

  /// 每周目标 - 用于记录每周的目标
  weeklyFocus,
  weeklySummary,

  /// 每月目标 - 用于记录每月的目标
  monthlyFocus,
  monthlySummary,

  /// 每年
  yearlyFocus,
  yearlySummary;

  /// 从字符串创建（用于数据库反序列化）
  static NoteType? fromString(String? value) {
    if (value == null) return null;
    return NoteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteType.journal,
    );
  }

  bool get isDaily => this == dailyFocus || this == dailySummary;

  bool get isWeekly => this == weeklyFocus || this == weeklySummary;

  bool get isMonthly => this == monthlyFocus || this == monthlySummary;
  bool get isYearly => this == yearlyFocus || this == yearlySummary;

  /// 是否为目标类型
  bool get isFocus =>
      this == dailyFocus ||
      this == weeklyFocus ||
      this == monthlyFocus ||
      this == yearlyFocus;

  /// 是否为总结类型
  bool get isSummary =>
      this == dailySummary ||
      this == weeklySummary ||
      this == monthlySummary ||
      this == yearlySummary;

  /// 是否为日记类型
  bool get isJournal => this == journal;

  static List<NoteType> get focusTypes => [
    dailyFocus,
    weeklyFocus,
    monthlyFocus,
    yearlyFocus,
  ];
  static List<NoteType> get summaryTypes => [
    dailySummary,
    weeklySummary,
    monthlySummary,
    yearlySummary,
  ];

  NoteType get sameRangeNoteType => switch (this) {
    NoteType.dailyFocus => NoteType.dailySummary,
    NoteType.dailySummary => NoteType.dailyFocus,
    NoteType.weeklyFocus => NoteType.weeklySummary,
    NoteType.weeklySummary => NoteType.weeklyFocus,
    NoteType.monthlyFocus => NoteType.monthlySummary,
    NoteType.monthlySummary => NoteType.monthlyFocus,
    NoteType.yearlyFocus => NoteType.yearlySummary,
    NoteType.yearlySummary => NoteType.yearlyFocus,
    NoteType.journal => NoteType.journal,
  };

  NoteType get focusType => switch (this) {
    NoteType.dailyFocus => NoteType.dailyFocus,
    NoteType.dailySummary => NoteType.dailyFocus,
    NoteType.weeklyFocus => NoteType.weeklyFocus,
    NoteType.weeklySummary => NoteType.weeklyFocus,
    NoteType.monthlyFocus => NoteType.monthlyFocus,
    NoteType.monthlySummary => NoteType.monthlyFocus,
    NoteType.yearlyFocus => NoteType.yearlyFocus,
    NoteType.yearlySummary => NoteType.yearlyFocus,
    _ => throw UnimplementedError(),
  };

  NoteType get summaryType => switch (this) {
    NoteType.dailyFocus => NoteType.dailySummary,
    NoteType.dailySummary => NoteType.dailySummary,
    NoteType.weeklyFocus => NoteType.weeklySummary,
    NoteType.weeklySummary => NoteType.weeklySummary,
    NoteType.monthlyFocus => NoteType.monthlySummary,
    NoteType.monthlySummary => NoteType.monthlySummary,
    NoteType.yearlyFocus => NoteType.yearlySummary,
    NoteType.yearlySummary => NoteType.yearlySummary,
    _ => throw UnimplementedError(),
  };
}
