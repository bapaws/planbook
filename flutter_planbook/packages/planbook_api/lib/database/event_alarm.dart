import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';

/// 提醒类型
enum AlertType {
  /// 相对时间提醒（例如：开始前15分钟）
  relative,

  /// 绝对时间提醒（指定具体日期时间）
  absolute,

  /// 某天/某周某时提醒（例如：当天 9 点、前一天 9 点、当周/一周前 9 点）
  scheduled;

  static AlertType? fromString(String? value) {
    if (value == null) return null;
    return AlertType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertType.relative,
    );
  }
}

/// 事件提醒（参照 EventKit 的 EKAlarm）
class EventAlarm extends Equatable {
  const EventAlarm({
    required this.type,
    this.relativeOffset,
    this.absoluteAt,
    this.dayOffset,
    this.weekOffset,
    this.hour,
    this.minute,
  }) : assert(
         (type == AlertType.relative && relativeOffset != null) ||
             (type == AlertType.absolute && absoluteAt != null) ||
             (type == AlertType.scheduled &&
                 (dayOffset != null || weekOffset != null) &&
                 hour != null &&
                 minute != null),
         'relative 需要 relativeOffset，absolute 需要 absoluteAt，'
         ' scheduled 需要 dayOffset/hour/minute',
       );

  /// 创建相对时间提醒（例如：任务开始前 15 分钟）
  factory EventAlarm.relative(int minutesBeforeStart) {
    return EventAlarm(
      type: AlertType.relative,
      relativeOffset: -minutesBeforeStart,
    );
  }

  /// 创建绝对时间提醒
  factory EventAlarm.absolute(Jiffy at) {
    return EventAlarm(
      type: AlertType.absolute,
      absoluteAt: at,
    );
  }

  /// 创建按天或周某时提醒（例如：当天 9 点、前一天 9 点）
  /// [dayOffset] 0=当天，-1=前一天，-2=前两天
  /// [hour] 0-23，默认 9（上午 9 点）
  /// [minute] 0-59，默认 0
  /// [weekOffset] 可选，0=当周，-1=一周前，-2=两周前；与 dayOffset 叠加
  factory EventAlarm.scheduled({
    int? dayOffset,
    int? weekOffset,
    int hour = 9,
    int minute = 0,
  }) {
    return EventAlarm(
      type: AlertType.scheduled,
      dayOffset: dayOffset,
      weekOffset: weekOffset,
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    );
  }

  /// 从 JSON 创建
  factory EventAlarm.fromJson(Map<String, dynamic> json) {
    // 支持新的 absoluteAt 格式
    Jiffy? absoluteAt;
    if (json.containsKey('absoluteAt') && json['absoluteAt'] != null) {
      absoluteAt = Jiffy.parse(json['absoluteAt'] as String);
    }
    // 向后兼容：支持旧的 absoluteDate 格式
    else if (json.containsKey('absoluteDate') && json['absoluteDate'] != null) {
      absoluteAt = Jiffy.parse(json['absoluteDate'] as String);
    }

    final type =
        AlertType.fromString(json['type'] as String?) ?? AlertType.relative;
    final dayOffset = json['dayOffset'] as int?;
    final weekOffset = json['weekOffset'] as int?;
    // scheduled 默认上午 9 点
    final hour = type == AlertType.scheduled
        ? (json['hour'] as int?) ?? 9
        : json['hour'] as int?;
    final minute = type == AlertType.scheduled
        ? (json['minute'] as int?) ?? 0
        : json['minute'] as int?;

    return EventAlarm(
      type: type,
      relativeOffset: json['relativeOffset'] as int?,
      absoluteAt: absoluteAt,
      dayOffset: dayOffset,
      weekOffset: weekOffset,
      hour: hour,
      minute: minute,
    );
  }

  /// 提醒类型
  final AlertType type;

  /// 相对偏移量（分钟，仅用于 relative 类型）
  /// 负数表示开始前，正数表示开始后
  /// 例如：-15 表示开始前15分钟
  final int? relativeOffset;

  /// 绝对提醒时间（仅用于 absolute 类型）
  final Jiffy? absoluteAt;

  /// 相对天数偏移（仅用于 scheduled 类型）
  /// 0=当天，-1=前一天，-2=前两天
  final int? dayOffset;

  /// 相对周数偏移（仅用于 scheduled 类型）
  /// 0=当周，-1=一周前，-2=两周前；与 dayOffset 叠加
  final int? weekOffset;

  /// 提醒时刻：时 0-23（仅用于 scheduled 类型）
  final int? hour;

  /// 提醒时刻：分 0-59（仅用于 scheduled 类型）
  final int? minute;

  /// 根据事件开始时间计算该提醒的实际触发时间（用于 relative / scheduled）
  /// [eventStart] 事件开始时间。数据不完整或提醒时间晚于事件开始时返回 null。
  /// [isAllDay] 是否全天任务。全天任务时，scheduled 类型的「当天」提醒（同一天某时刻）视为有效。
  Jiffy? resolveTriggerTime(Jiffy eventStart, {bool isAllDay = false}) {
    switch (type) {
      case AlertType.relative:
        if (relativeOffset == null) return null;
        final t = eventStart.add(minutes: relativeOffset!);
        return t.isAfter(eventStart) ? null : t;
      case AlertType.scheduled:
        if (dayOffset == null && weekOffset == null) return null;
        final h = hour ?? 9;
        final m = minute ?? 0;
        final t = eventStart
            .add(weeks: weekOffset ?? 0)
            .add(days: dayOffset ?? 0)
            .startOf(Unit.day)
            .add(hours: h, minutes: m);
        if (isAllDay && t.isSame(eventStart, unit: Unit.day)) return t;
        return t.isAfter(eventStart) ? null : t;
      case AlertType.absolute:
        return absoluteAt;
    }
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (relativeOffset != null) 'relativeOffset': relativeOffset,
      if (absoluteAt != null) 'absoluteAt': absoluteAt!.format(),
      if (dayOffset != null) 'dayOffset': dayOffset,
      if (weekOffset != null) 'weekOffset': weekOffset,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
    };
  }

  @override
  List<Object?> get props => [
    type,
    relativeOffset,
    absoluteAt?.format(),
    dayOffset,
    weekOffset,
    hour,
    minute,
  ];
}

/// EventAlarm 列表的 Drift 类型转换器
class EventAlarmListConverter extends TypeConverter<List<EventAlarm>, String?>
    with JsonTypeConverter2<List<EventAlarm>, String?, String?> {
  const EventAlarmListConverter();

  @override
  List<EventAlarm> fromSql(String? fromDb) {
    if (fromDb == null) return [];
    final json = jsonDecode(fromDb) as List<dynamic>;
    return json
        .map((e) => EventAlarm.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  String? toSql(List<EventAlarm>? value) {
    if (value == null || value.isEmpty) return null;
    return jsonEncode(value.map((e) => e.toJson()).toList());
  }

  @override
  List<EventAlarm> fromJson(String? json) {
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => EventAlarm.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  String? toJson(List<EventAlarm>? value) {
    if (value == null || value.isEmpty) return null;
    return jsonEncode(value.map((e) => e.toJson()).toList());
  }
}
