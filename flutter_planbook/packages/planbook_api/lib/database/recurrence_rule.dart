import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';

/// 重复结束条件（参照 EventKit 的 EKRecurrenceEnd）
///
/// 用于定义重复事件的结束条件，可以通过结束日期或重复次数来指定
class RecurrenceEnd extends Equatable {
  /// 从 JSON 创建
  factory RecurrenceEnd.fromJson(Map<String, dynamic> json) {
    // 支持新的 endAt 格式
    if (json.containsKey('endAt') && json['endAt'] != null) {
      return RecurrenceEnd.fromEndAt(
        Jiffy.parse(json['endAt'] as String),
      );
    } else if (json.containsKey('occurrenceCount') &&
        json['occurrenceCount'] != null) {
      return RecurrenceEnd.fromOccurrenceCount(
        json['occurrenceCount'] as int,
      );
    }
    throw ArgumentError(
      'RecurrenceEnd JSON 必须包含 endAt 或 occurrenceCount',
    );
  }

  /// 通过结束日期创建
  factory RecurrenceEnd.fromEndAt(Jiffy endAt) {
    return RecurrenceEnd._(endAt: endAt);
  }

  /// 通过重复次数创建
  factory RecurrenceEnd.fromOccurrenceCount(int occurrenceCount) {
    return RecurrenceEnd._(
      occurrenceCount: occurrenceCount,
    );
  }

  const RecurrenceEnd._({
    this.endAt,
    this.occurrenceCount,
  }) : assert(
         (endAt != null && occurrenceCount == null) ||
             (endAt == null && occurrenceCount != null),
         '必须提供 endAt 或 occurrenceCount 其中之一，但不能同时提供',
       );

  /// 结束日期（可选，与 occurrenceCount 互斥）
  final Jiffy? endAt;

  /// 重复次数（可选，与 endAt 互斥）
  final int? occurrenceCount;

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      if (endAt != null) 'endAt': endAt!.format(),
      if (occurrenceCount != null) 'occurrenceCount': occurrenceCount,
    };
  }

  @override
  List<Object?> get props => [
    endAt?.format(),
    occurrenceCount,
  ];
}

/// 星期几枚举（与 Flutter DateTime.weekday 保持一致）
///
/// 值对应关系：
/// - Monday = 1
/// - Tuesday = 2
/// - Wednesday = 3
/// - Thursday = 4
/// - Friday = 5
/// - Saturday = 6
/// - Sunday = 7
enum Weekday {
  /// 星期一
  monday(1),

  /// 星期二
  tuesday(2),

  /// 星期三
  wednesday(3),

  /// 星期四
  thursday(4),

  /// 星期五
  friday(5),

  /// 星期六
  saturday(6),

  /// 星期日
  sunday(7);

  const Weekday(this.value);

  /// 星期几的值（与 DateTime.weekday 一致）
  final int value;

  /// 从整数值创建（与 DateTime.weekday 值对应）
  static Weekday? fromValue(int? value) {
    if (value == null) return null;
    return Weekday.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Weekday.monday,
    );
  }

  /// 从 DateTime.weekday 创建
  static Weekday fromDateTimeWeekday(int weekday) {
    return fromValue(weekday) ?? Weekday.monday;
  }

  /// 转换为 DateTime.weekday 值
  int toDateTimeWeekday() => value;
}

/// 重复规则中的星期几（参照 EventKit 的 EKRecurrenceDayOfWeek）
///
/// 用于指定重复规则中的特定星期几，可以包含周数信息（例如：每月的第一个星期一）
class RecurrenceDayOfWeek extends Equatable {
  /// 从 JSON 创建
  factory RecurrenceDayOfWeek.fromJson(Map<String, dynamic> json) {
    final dayValue = json['dayOfTheWeek'] as int;
    final day = Weekday.fromValue(dayValue) ?? Weekday.monday;
    final weekNumber = json['weekNumber'] as int?;

    if (weekNumber != null && weekNumber != 0) {
      return RecurrenceDayOfWeek.dayWithWeekNumber(day, weekNumber);
    } else {
      return RecurrenceDayOfWeek.day(day);
    }
  }

  /// 创建不指定周数的星期几（用于 weekly 频率）
  factory RecurrenceDayOfWeek.day(Weekday dayOfTheWeek) {
    return RecurrenceDayOfWeek._(
      dayOfTheWeek: dayOfTheWeek,
    );
  }

  /// 创建指定周数的星期几（用于 monthly 频率）
  ///
  /// [weekNumber] 表示该星期几在月份中的位置：
  /// - 正数：从月初开始，1=第一个，2=第二个...
  /// - 负数：从月末开始，-1=最后一个，-2=倒数第二个...
  factory RecurrenceDayOfWeek.dayWithWeekNumber(
    Weekday dayOfTheWeek,
    int weekNumber,
  ) {
    assert(
      weekNumber != 0,
      'weekNumber 不能为 0，使用正数表示从月初开始，负数表示从月末开始',
    );
    return RecurrenceDayOfWeek._(
      dayOfTheWeek: dayOfTheWeek,
      weekNumber: weekNumber,
    );
  }

  const RecurrenceDayOfWeek._({
    required this.dayOfTheWeek,
    this.weekNumber,
  });

  /// 星期几
  final Weekday dayOfTheWeek;

  /// 周数（可选）
  /// - 正数：从月初开始，1=第一个，2=第二个...
  /// - 负数：从月末开始，-1=最后一个，-2=倒数第二个...
  /// - null：不指定周数（用于 weekly 频率）
  final int? weekNumber;

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'dayOfTheWeek': dayOfTheWeek.value,
      if (weekNumber != null) 'weekNumber': weekNumber,
    };
  }

  @override
  List<Object?> get props => [
    dayOfTheWeek,
    weekNumber,
  ];
}

/// 重复频率
enum RecurrenceFrequency {
  /// 每天
  daily,

  /// 每周
  weekly,

  /// 每月
  monthly,

  /// 每年
  yearly;

  static RecurrenceFrequency? fromString(String? value) {
    if (value == null) return null;
    return RecurrenceFrequency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecurrenceFrequency.daily,
    );
  }
}

/// 重复规则（参照 EventKit 的 EKRecurrenceRule）
class RecurrenceRule extends Equatable {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.recurrenceEnd,
    this.daysOfWeek,
    this.daysOfMonth,
    this.weeksOfMonth,
    this.monthsOfYear,
    this.daysOfYear,
  });

  /// 创建带结束日期的重复规则
  factory RecurrenceRule.withEndAt({
    required RecurrenceFrequency frequency,
    required Jiffy endAt,
    int interval = 1,
    List<RecurrenceDayOfWeek>? daysOfWeek,
    List<int>? daysOfMonth,
    List<int>? weeksOfMonth,
    List<int>? monthsOfYear,
    List<int>? daysOfYear,
  }) {
    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      recurrenceEnd: RecurrenceEnd.fromEndAt(endAt),
      daysOfWeek: daysOfWeek,
      daysOfMonth: daysOfMonth,
      weeksOfMonth: weeksOfMonth,
      monthsOfYear: monthsOfYear,
      daysOfYear: daysOfYear,
    );
  }

  /// 创建带重复次数的重复规则
  factory RecurrenceRule.withOccurrenceCount({
    required RecurrenceFrequency frequency,
    required int occurrenceCount,
    int interval = 1,
    List<RecurrenceDayOfWeek>? daysOfWeek,
    List<int>? daysOfMonth,
    List<int>? weeksOfMonth,
    List<int>? monthsOfYear,
    List<int>? daysOfYear,
  }) {
    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      recurrenceEnd: RecurrenceEnd.fromOccurrenceCount(occurrenceCount),
      daysOfWeek: daysOfWeek,
      daysOfMonth: daysOfMonth,
      weeksOfMonth: weeksOfMonth,
      monthsOfYear: monthsOfYear,
      daysOfYear: daysOfYear,
    );
  }

  /// 从 JSON 创建
  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    RecurrenceEnd? recurrenceEnd;
    // 支持新的 recurrenceEnd 格式
    if (json.containsKey('recurrenceEnd') && json['recurrenceEnd'] != null) {
      recurrenceEnd = RecurrenceEnd.fromJson(
        json['recurrenceEnd'] as Map<String, dynamic>,
      );
    }
    // 向后兼容：支持旧的 endDate 格式（已在 RecurrenceEnd.fromJson 中处理）
    else if (json.containsKey('occurrenceCount') &&
        json['occurrenceCount'] != null) {
      recurrenceEnd = RecurrenceEnd.fromOccurrenceCount(
        json['occurrenceCount'] as int,
      );
    }

    // 解析 daysOfWeek
    List<RecurrenceDayOfWeek>? daysOfWeek;
    if (json['daysOfWeek'] != null) {
      final daysOfWeekJson = json['daysOfWeek'] as List;
      // 支持新的 RecurrenceDayOfWeek 格式
      if (daysOfWeekJson.isNotEmpty &&
          daysOfWeekJson.first is Map<String, dynamic>) {
        daysOfWeek = daysOfWeekJson
            .map((e) => RecurrenceDayOfWeek.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // 向后兼容：支持旧的 int 格式（0-6，需要转换为 1-7）
      else if (daysOfWeekJson.isNotEmpty && daysOfWeekJson.first is int) {
        daysOfWeek = (daysOfWeekJson as List<int>).map((day) {
          // 旧格式：0=Sunday, 1=Monday, ..., 6=Saturday
          // 新格式：1=Monday, 2=Tuesday, ..., 7=Sunday
          int convertedDay;
          if (day == 0) {
            convertedDay = 7; // Sunday
          } else {
            convertedDay = day; // Monday-Saturday
          }
          return RecurrenceDayOfWeek.day(
            Weekday.fromValue(convertedDay) ?? Weekday.monday,
          );
        }).toList();
      }
    }

    return RecurrenceRule(
      frequency:
          RecurrenceFrequency.fromString(json['frequency'] as String?) ??
          RecurrenceFrequency.daily,
      interval: json['interval'] as int? ?? 1,
      recurrenceEnd: recurrenceEnd,
      daysOfWeek: daysOfWeek,
      daysOfMonth: json['daysOfMonth'] != null
          ? List<int>.from(json['daysOfMonth'] as List)
          : null,
      weeksOfMonth: json['weeksOfMonth'] != null
          ? List<int>.from(json['weeksOfMonth'] as List)
          : null,
      monthsOfYear: json['monthsOfYear'] != null
          ? List<int>.from(json['monthsOfYear'] as List)
          : null,
      daysOfYear: json['daysOfYear'] != null
          ? List<int>.from(json['daysOfYear'] as List)
          : null,
    );
  }

  /// 重复频率
  final RecurrenceFrequency frequency;

  /// 重复间隔（例如：每2天、每3周）
  final int interval;

  /// 重复结束条件（可选）
  final RecurrenceEnd? recurrenceEnd;

  /// 每周的星期几（用于 weekly 和 monthly 频率）
  final List<RecurrenceDayOfWeek>? daysOfWeek;

  /// 每月的第几天（仅用于 monthly）
  final List<int>? daysOfMonth; // 1-31

  /// 每月的第几周（仅用于 monthly）
  final List<int>? weeksOfMonth; // -1 = last week, 1-4 = first to fourth week

  /// 每年的月份（仅用于 yearly）
  @Deprecated('Use daysOfYear instead')
  final List<int>? monthsOfYear;

  /// 每年的第几天（仅用于 yearly）
  final List<int>? daysOfYear; // month * 100 + day

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      if (recurrenceEnd != null) 'recurrenceEnd': recurrenceEnd!.toJson(),
      if (daysOfWeek != null)
        'daysOfWeek': daysOfWeek!.map((e) => e.toJson()).toList(),
      if (daysOfMonth != null) 'daysOfMonth': daysOfMonth,
      if (weeksOfMonth != null) 'weeksOfMonth': weeksOfMonth,
      if (monthsOfYear != null) 'monthsOfYear': monthsOfYear,
      if (daysOfYear != null) 'daysOfYear': daysOfYear,
    };
  }

  @override
  List<Object?> get props => [
    frequency,
    interval,
    recurrenceEnd,
    daysOfWeek,
    daysOfMonth,
    weeksOfMonth,
    monthsOfYear,
    daysOfYear,
  ];

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    ValueGetter<RecurrenceEnd?>? recurrenceEnd,
    List<RecurrenceDayOfWeek>? daysOfWeek,
    List<int>? daysOfMonth,
    List<int>? weeksOfMonth,
    List<int>? monthsOfYear,
    List<int>? daysOfYear,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      recurrenceEnd: recurrenceEnd != null
          ? recurrenceEnd()
          : this.recurrenceEnd,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      daysOfMonth: daysOfMonth ?? this.daysOfMonth,
      weeksOfMonth: weeksOfMonth ?? this.weeksOfMonth,
      monthsOfYear: monthsOfYear ?? this.monthsOfYear,
      daysOfYear: daysOfYear ?? this.daysOfYear,
    );
  }
}

/// RecurrenceRule 的 Drift 类型转换器
class RecurrenceRuleConverter extends TypeConverter<RecurrenceRule?, String?>
    with JsonTypeConverter2<RecurrenceRule?, String?, String?> {
  const RecurrenceRuleConverter();

  @override
  RecurrenceRule? fromSql(String? fromDb) {
    if (fromDb == null) return null;

    final json = jsonDecode(fromDb) as Map<String, dynamic>;
    return RecurrenceRule.fromJson(json);
  }

  @override
  String? toSql(RecurrenceRule? value) {
    if (value == null) return null;
    return jsonEncode(value.toJson());
  }

  @override
  RecurrenceRule? fromJson(String? json) {
    if (json == null) return null;
    return RecurrenceRule.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  String? toJson(RecurrenceRule? value) {
    if (value == null) return null;
    return jsonEncode(value.toJson());
  }
}
