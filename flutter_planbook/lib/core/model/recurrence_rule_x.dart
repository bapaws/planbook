import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/database/recurrence_rule.dart';

extension RecurrenceRuleX on RecurrenceRule {
  /// 获取重复规则的描述文本
  /// 例如：每 1 天、每 2 周，结束于 2025/1/1
  String getTitle(AppLocalizations l10n) {
    // 构建频率描述：每 N 天/周/月/年
    final unitName = frequency.getEveryUnitName(l10n);
    final frequencyText = l10n.everyInterval(interval, unitName);

    // 构建结束条件描述
    final end = recurrenceEnd;
    if (end == null) {
      // 无限期重复
      return frequencyText;
    }

    if (end.endAt != null) {
      // 结束于指定日期
      final dateStr = end.endAt!.format(pattern: 'yyyy/M/d');
      return l10n.recurrenceWithEndDate(frequencyText, dateStr);
    }

    if (end.occurrenceCount != null) {
      // 结束于指定次数
      return l10n.recurrenceWithEndCount(frequencyText, end.occurrenceCount!);
    }

    return frequencyText;
  }
}

extension _RecurrenceFrequencyX on RecurrenceFrequency {
  String getEveryUnitName(AppLocalizations l10n) => switch (this) {
    RecurrenceFrequency.daily => l10n.everyDay,
    RecurrenceFrequency.weekly => l10n.everyWeek,
    RecurrenceFrequency.monthly => l10n.everyMonth,
    RecurrenceFrequency.yearly => l10n.everyYear,
  };
}
