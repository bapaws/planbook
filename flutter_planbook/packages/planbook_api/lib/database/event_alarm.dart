import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';

/// 提醒类型
enum AlertType {
  /// 相对时间提醒（例如：开始前15分钟）
  relative,

  /// 绝对时间提醒（指定具体日期时间）
  absolute;

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
  }) : assert(
         (type == AlertType.relative && relativeOffset != null) ||
             (type == AlertType.absolute && absoluteAt != null),
         'relative 类型需要 relativeOffset，absolute 类型需要 absoluteAt',
       );

  /// 创建相对时间提醒
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

    return EventAlarm(
      type: AlertType.fromString(json['type'] as String?) ?? AlertType.relative,
      relativeOffset: json['relativeOffset'] as int?,
      absoluteAt: absoluteAt,
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

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (relativeOffset != null) 'relativeOffset': relativeOffset,
      if (absoluteAt != null) 'absoluteAt': absoluteAt!.format(),
    };
  }

  @override
  List<Object?> get props => [
    type,
    relativeOffset,
    absoluteAt?.format(),
  ];
}

/// EventAlarm 列表的 Drift 类型转换器
class EventAlarmListConverter extends TypeConverter<List<EventAlarm>, String?>
    with JsonTypeConverter2<List<EventAlarm>, String?, List<dynamic>?> {
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
  List<EventAlarm> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((e) => EventAlarm.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<EventAlarm>? value) {
    if (value == null || value.isEmpty) return [];
    return value.map((e) => e.toJson()).toList();
  }
}
