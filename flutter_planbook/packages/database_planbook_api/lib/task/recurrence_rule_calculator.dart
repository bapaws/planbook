import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/recurrence_rule.dart';

/// 重复规则计算器
///
/// 负责处理 RecurrenceRule 的业务逻辑计算，包括：
/// - 判断任务在指定日期是否需要执行
/// - 生成指定日期范围内的所有任务实例日期
class RecurrenceRuleCalculator {
  RecurrenceRuleCalculator._();

  /// 判断任务在指定日期是否需要执行
  ///
  /// [rule] 重复规则
  /// [startDate] 任务的起始日期（任务的 startAt 或 dueAt）
  /// [targetDate] 要检查的目标日期
  ///
  /// 返回 true 表示该任务在目标日期需要执行，false 表示不需要执行
  static bool shouldOccurOnDate({
    required RecurrenceRule rule,
    required Jiffy startDate,
    required Jiffy targetDate,
  }) {
    // 目标日期必须在起始日期之后或等于起始日期
    if (targetDate.isBefore(startDate, unit: Unit.day)) {
      return false;
    }

    // 检查是否超过结束日期
    if (rule.recurrenceEnd?.endAt != null) {
      if (targetDate.isAfter(rule.recurrenceEnd!.endAt!, unit: Unit.day)) {
        return false;
      }
    }

    // 根据频率类型判断
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return _shouldOccurDaily(rule, startDate, targetDate);

      case RecurrenceFrequency.weekly:
        return _shouldOccurWeekly(rule, startDate, targetDate);

      case RecurrenceFrequency.monthly:
        return _shouldOccurMonthly(rule, startDate, targetDate);

      case RecurrenceFrequency.yearly:
        return _shouldOccurYearly(rule, startDate, targetDate);
    }
  }

  /// 判断每日重复是否在目标日期执行
  static bool _shouldOccurDaily(
    RecurrenceRule rule,
    Jiffy startDate,
    Jiffy targetDate,
  ) {
    // 计算从起始日期到目标日期的天数差
    final daysDiff = targetDate.diff(startDate, unit: Unit.day);

    // 必须能被 interval 整除
    if (daysDiff % rule.interval != 0) {
      return false;
    }

    // 检查是否超过重复次数限制
    if (rule.recurrenceEnd?.occurrenceCount != null) {
      final occurrenceIndex = daysDiff ~/ rule.interval;
      if (occurrenceIndex >= rule.recurrenceEnd!.occurrenceCount!) {
        return false;
      }
    }

    return true;
  }

  /// 判断每周重复是否在目标日期执行
  static bool _shouldOccurWeekly(
    RecurrenceRule rule,
    Jiffy startDate,
    Jiffy targetDate,
  ) {
    // 如果指定了星期几，检查目标日期是否匹配
    if (rule.daysOfWeek != null && rule.daysOfWeek!.isNotEmpty) {
      final targetWeekday = Weekday.fromDateTimeWeekday(
        targetDate.dateTime.weekday,
      );
      final matchesDayOfWeek = rule.daysOfWeek!.any(
        (dayOfWeek) => dayOfWeek.dayOfTheWeek == targetWeekday,
      );
      if (!matchesDayOfWeek) {
        return false;
      }
    }

    // 计算从起始日期到目标日期的周数差
    final weeksDiff = targetDate.diff(startDate, unit: Unit.week);

    // 必须能被 interval 整除
    if (weeksDiff % rule.interval != 0) {
      return false;
    }

    // 检查是否超过重复次数限制
    if (rule.recurrenceEnd?.occurrenceCount != null) {
      final occurrenceIndex = weeksDiff ~/ rule.interval;
      if (occurrenceIndex >= rule.recurrenceEnd!.occurrenceCount!) {
        return false;
      }
    }

    return true;
  }

  /// 判断每月重复是否在目标日期执行
  static bool _shouldOccurMonthly(
    RecurrenceRule rule,
    Jiffy startDate,
    Jiffy targetDate,
  ) {
    // 计算从起始日期到目标日期的月数差
    final monthsDiff = targetDate.diff(startDate, unit: Unit.month);

    // 必须能被 interval 整除
    if (monthsDiff % rule.interval != 0) {
      return false;
    }

    // 检查是否超过重复次数限制
    if (rule.recurrenceEnd?.occurrenceCount != null) {
      final occurrenceIndex = monthsDiff ~/ rule.interval;
      if (occurrenceIndex >= rule.recurrenceEnd!.occurrenceCount!) {
        return false;
      }
    }

    // 如果指定了每月的第几天
    if (rule.daysOfMonth != null && rule.daysOfMonth!.isNotEmpty) {
      if (!rule.daysOfMonth!.contains(targetDate.date)) {
        return false;
      }
    }

    // 如果指定了每月的第几周和星期几
    if (rule.daysOfWeek != null &&
        rule.daysOfWeek!.isNotEmpty &&
        rule.weeksOfMonth != null &&
        rule.weeksOfMonth!.isNotEmpty) {
      final targetWeekday = Weekday.fromDateTimeWeekday(
        targetDate.dateTime.weekday,
      );
      final weekOfMonth = _getWeekOfMonth(targetDate);

      final matches = rule.daysOfWeek!.any((dayOfWeek) {
        if (dayOfWeek.dayOfTheWeek != targetWeekday) {
          return false;
        }

        // 如果指定了周数，检查是否匹配
        if (dayOfWeek.weekNumber != null) {
          return rule.weeksOfMonth!.contains(dayOfWeek.weekNumber) &&
              weekOfMonth == dayOfWeek.weekNumber;
        } else {
          // 没有指定周数，只检查星期几是否在 weeksOfMonth 中
          return rule.weeksOfMonth!.contains(weekOfMonth);
        }
      });

      if (!matches) {
        return false;
      }
    } else if (rule.daysOfWeek != null && rule.daysOfWeek!.isNotEmpty) {
      // 只指定了星期几，没有指定周数
      final targetWeekday = Weekday.fromDateTimeWeekday(
        targetDate.dateTime.weekday,
      );
      final matchesDayOfWeek = rule.daysOfWeek!.any(
        (dayOfWeek) => dayOfWeek.dayOfTheWeek == targetWeekday,
      );
      if (!matchesDayOfWeek) {
        return false;
      }
    }

    return true;
  }

  /// 判断每年重复是否在目标日期执行
  static bool _shouldOccurYearly(
    RecurrenceRule rule,
    Jiffy startDate,
    Jiffy targetDate,
  ) {
    // 计算从起始日期到目标日期的年数差
    final yearsDiff = targetDate.diff(startDate, unit: Unit.year);

    // 必须能被 interval 整除
    if (yearsDiff % rule.interval != 0) {
      return false;
    }

    // 检查是否超过重复次数限制
    if (rule.recurrenceEnd?.occurrenceCount != null) {
      final occurrenceIndex = yearsDiff ~/ rule.interval;
      if (occurrenceIndex >= rule.recurrenceEnd!.occurrenceCount!) {
        return false;
      }
    }

    // 如果指定了每年的第几天，检查目标日期的月份和日期是否匹配
    if (rule.daysOfYear != null && rule.daysOfYear!.isNotEmpty) {
      if (!rule.daysOfYear!.contains(
        targetDate.month * 100 + targetDate.date,
      )) {
        return false;
      }
    }

    // 如果指定了每月的第几周和星期几
    if (rule.daysOfWeek != null &&
        rule.daysOfWeek!.isNotEmpty &&
        rule.weeksOfMonth != null &&
        rule.weeksOfMonth!.isNotEmpty) {
      final targetWeekday = Weekday.fromDateTimeWeekday(
        targetDate.dateTime.weekday,
      );
      final weekOfMonth = _getWeekOfMonth(targetDate);

      final matches = rule.daysOfWeek!.any((dayOfWeek) {
        if (dayOfWeek.dayOfTheWeek != targetWeekday) {
          return false;
        }

        if (dayOfWeek.weekNumber != null) {
          return rule.weeksOfMonth!.contains(dayOfWeek.weekNumber) &&
              weekOfMonth == dayOfWeek.weekNumber;
        } else {
          return rule.weeksOfMonth!.contains(weekOfMonth);
        }
      });

      if (!matches) {
        return false;
      }
    } else if (rule.daysOfWeek != null && rule.daysOfWeek!.isNotEmpty) {
      final targetWeekday = Weekday.fromDateTimeWeekday(
        targetDate.dateTime.weekday,
      );
      final matchesDayOfWeek = rule.daysOfWeek!.any(
        (dayOfWeek) => dayOfWeek.dayOfTheWeek == targetWeekday,
      );
      if (!matchesDayOfWeek) {
        return false;
      }
    }

    return true;
  }

  /// 获取日期在月份中的周数
  ///
  /// 返回 1-4 表示第几周，-1 表示最后一周
  static int _getWeekOfMonth(Jiffy date) {
    // 获取该月第一天是星期几
    final firstDayOfMonth = date.startOf(Unit.month);
    final firstDayWeekday = firstDayOfMonth.dateTime.weekday;

    // 计算目标日期是该月的第几天
    final dayOfMonth = date.date;

    // 计算目标日期是该月的第几周（从1开始）
    // 第一周：从1号到第一个星期日的天数
    // 后续周：每7天一周
    final weekNumber = ((dayOfMonth - 1 + firstDayWeekday - 1) ~/ 7) + 1;

    // 检查是否是最后一周
    final lastDayOfMonth = date.endOf(Unit.month);
    final lastDayWeekday = lastDayOfMonth.dateTime.weekday;
    final daysInMonth = lastDayOfMonth.date;
    final lastWeekNumber = ((daysInMonth - 1 + firstDayWeekday - 1) ~/ 7) + 1;

    // 如果目标日期在最后一周，且最后一周的天数少于7天，可能需要特殊处理
    // 这里简化处理：如果 weekNumber 等于 lastWeekNumber，且目标日期接近月末，返回 -1
    if (weekNumber == lastWeekNumber && dayOfMonth > daysInMonth - 7) {
      // 检查是否真的是最后一周（从最后一个星期日往前推）
      final daysFromEnd = daysInMonth - dayOfMonth;
      if (daysFromEnd < lastDayWeekday) {
        return -1; // 最后一周
      }
    }

    return weekNumber;
  }

  /// 生成指定日期范围内的所有任务实例日期
  ///
  /// [rule] 重复规则
  /// [startDate] 任务的起始日期
  /// [rangeStart] 要生成实例的开始日期
  /// [rangeEnd] 要生成实例的结束日期
  ///
  /// 返回所有在指定范围内需要执行任务的日期列表
  static List<Jiffy> generateOccurrences({
    required RecurrenceRule rule,
    required Jiffy startDate,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    // 确保范围开始日期不早于任务起始日期
    final effectiveStart = rangeStart.isBefore(startDate, unit: Unit.day)
        ? startDate
        : rangeStart;

    // 检查是否超过结束日期
    if (rule.recurrenceEnd?.endAt != null) {
      final endAt = rule.recurrenceEnd!.endAt!;
      if (effectiveStart.isAfter(endAt, unit: Unit.day)) {
        return <Jiffy>[]; // 范围开始日期已经超过结束日期
      }
      // 调整范围结束日期，不超过重复结束日期
      final effectiveEnd = rangeEnd.isAfter(endAt, unit: Unit.day)
          ? endAt
          : rangeEnd;

      return _generateOccurrencesInRange(
        rule: rule,
        startDate: startDate,
        rangeStart: effectiveStart,
        rangeEnd: effectiveEnd,
      );
    } else {
      return _generateOccurrencesInRange(
        rule: rule,
        startDate: startDate,
        rangeStart: effectiveStart,
        rangeEnd: rangeEnd,
      );
    }
  }

  /// 在指定范围内生成实例（内部方法）
  static List<Jiffy> _generateOccurrencesInRange({
    required RecurrenceRule rule,
    required Jiffy startDate,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return _generateDailyOccurrences(
          rule: rule,
          startDate: startDate,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );
      case RecurrenceFrequency.weekly:
        return _generateWeeklyOccurrences(
          rule: rule,
          startDate: startDate,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );
      case RecurrenceFrequency.monthly:
        return _generateMonthlyOccurrences(
          rule: rule,
          startDate: startDate,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );
      case RecurrenceFrequency.yearly:
        return _generateYearlyOccurrences(
          rule: rule,
          startDate: startDate,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );
    }
  }

  static List<Jiffy> _generateDailyOccurrences({
    required RecurrenceRule rule,
    required Jiffy startDate,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    final occurrences = <Jiffy>[];

    // 找到第一个可能的日期
    var currentDate = rangeStart.startOf(Unit.day);
    final startDateStart = startDate.startOf(Unit.day);

    // 如果当前日期早于起始日期，跳到起始日期
    if (currentDate.isBefore(startDateStart, unit: Unit.day)) {
      currentDate = startDateStart;
    }

    // 计算从起始日期到当前日期的天数差
    var daysDiff = currentDate.diff(startDateStart, unit: Unit.day);

    // 调整到第一个满足 interval 的日期
    final remainder = daysDiff % rule.interval;
    if (remainder != 0) {
      currentDate = currentDate.add(days: (rule.interval - remainder).toInt());
      daysDiff = currentDate.diff(startDateStart, unit: Unit.day);
    }

    // 检查重复次数限制
    int? maxOccurrences;
    if (rule.recurrenceEnd?.occurrenceCount != null) {
      maxOccurrences = rule.recurrenceEnd!.occurrenceCount;
    }

    // 生成所有满足条件的日期
    while (!currentDate.isAfter(rangeEnd, unit: Unit.day)) {
      if (maxOccurrences != null) {
        final occurrenceIndex = daysDiff ~/ rule.interval;
        if (occurrenceIndex >= maxOccurrences) {
          break;
        }
      }

      occurrences.add(currentDate);
      currentDate = currentDate.add(days: rule.interval);
      daysDiff += rule.interval;
    }

    return occurrences;
  }

  static List<Jiffy> _generateWeeklyOccurrences({
    required RecurrenceRule rule,
    required Jiffy startDate,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    final occurrences = <Jiffy>[];
    final startDateStart = startDate.startOf(Unit.day);
    var currentDate = rangeStart.startOf(Unit.day);

    // 如果指定了星期几，只生成匹配的日期
    if (rule.daysOfWeek != null && rule.daysOfWeek!.isNotEmpty) {
      final targetWeekdays = rule.daysOfWeek!
          .map((dow) => dow.dayOfTheWeek.value)
          .toSet();

      // 从范围开始日期往前找到第一个匹配的星期几
      while (!currentDate.isAfter(rangeEnd, unit: Unit.day)) {
        final weekday = currentDate.dateTime.weekday;
        if (targetWeekdays.contains(weekday)) {
          // 检查是否满足间隔和周数要求
          if (shouldOccurOnDate(
            rule: rule,
            startDate: startDateStart,
            targetDate: currentDate,
          )) {
            occurrences.add(currentDate);
          }
        }
        currentDate = currentDate.add(days: 1);
      }
    } else {
      // 没有指定星期几，按周间隔生成
      var weeksDiff = currentDate.diff(startDateStart, unit: Unit.week);
      final remainder = weeksDiff % rule.interval;
      if (remainder != 0) {
        currentDate = currentDate.add(
          weeks: (rule.interval - remainder).toInt(),
        );
        weeksDiff = currentDate.diff(startDateStart, unit: Unit.week);
      }

      int? maxOccurrences;
      if (rule.recurrenceEnd?.occurrenceCount != null) {
        maxOccurrences = rule.recurrenceEnd!.occurrenceCount;
      }

      while (!currentDate.isAfter(rangeEnd, unit: Unit.day)) {
        if (maxOccurrences != null) {
          final occurrenceIndex = weeksDiff ~/ rule.interval;
          if (occurrenceIndex >= maxOccurrences) {
            break;
          }
        }

        occurrences.add(currentDate);
        currentDate = currentDate.add(weeks: rule.interval);
        weeksDiff += rule.interval;
      }
    }

    return occurrences;
  }

  static List<Jiffy> _generateMonthlyOccurrences({
    required RecurrenceRule rule,
    required Jiffy startDate,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    final occurrences = <Jiffy>[];
    final startDateStart = startDate.startOf(Unit.day);
    var currentDate = rangeStart.startOf(Unit.day);

    // 如果指定了每月的第几天
    if (rule.daysOfMonth != null && rule.daysOfMonth!.isNotEmpty) {
      while (!currentDate.isAfter(rangeEnd, unit: Unit.day)) {
        if (rule.daysOfMonth!.contains(currentDate.date)) {
          if (shouldOccurOnDate(
            rule: rule,
            startDate: startDateStart,
            targetDate: currentDate,
          )) {
            occurrences.add(currentDate);
          }
        }
        currentDate = currentDate.add(days: 1);
      }
    } else {
      // 使用 shouldOccurOnDate 方法检查每个日期
      while (!currentDate.isAfter(rangeEnd, unit: Unit.day)) {
        if (shouldOccurOnDate(
          rule: rule,
          startDate: startDateStart,
          targetDate: currentDate,
        )) {
          occurrences.add(currentDate);
        }
        currentDate = currentDate.add(days: 1);
      }
    }

    return occurrences;
  }

  static List<Jiffy> _generateYearlyOccurrences({
    required RecurrenceRule rule,
    required Jiffy startDate,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    final occurrences = <Jiffy>[];
    final startDateStart = startDate.startOf(Unit.day);
    var currentDate = rangeStart.startOf(Unit.day);

    // 使用 shouldOccurOnDate 方法检查每个日期
    while (!currentDate.isAfter(rangeEnd, unit: Unit.day)) {
      if (shouldOccurOnDate(
        rule: rule,
        startDate: startDateStart,
        targetDate: currentDate,
      )) {
        occurrences.add(currentDate);
      }
      currentDate = currentDate.add(days: 1);
    }

    return occurrences;
  }
}
