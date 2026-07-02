import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:planbook_api/database/task_priority.dart';

/// 四象限自定义配置（按优先级维度）
///
/// [name] 为 null 时表示使用 l10n 默认名称
final class QuadrantConfigEntity extends Equatable {
  const QuadrantConfigEntity({
    required this.priority,
    this.name,
  });

  factory QuadrantConfigEntity.fromJson(Map<String, dynamic> json) {
    return QuadrantConfigEntity(
      priority: TaskPriority.values.byName(json['priority'] as String),
      name: json['name'] as String?,
    );
  }

  final TaskPriority priority;
  final String? name;

  /// 是否为默认状态（名称未自定义）
  bool get isDefault => name == null || name!.isEmpty;

  QuadrantConfigEntity copyWith({
    TaskPriority? priority,
    ValueGetter<String?>? name,
  }) {
    return QuadrantConfigEntity(
      priority: priority ?? this.priority,
      name: name != null ? name() : this.name,
    );
  }

  @override
  List<Object?> get props => [priority, name];

  Map<String, dynamic> toJson() {
    return {
      'priority': priority.name,
      'name': name,
    };
  }

  /// 默认配置列表（全部未自定义），顺序与 [TaskPriority.values] 一致
  static List<QuadrantConfigEntity> get defaults => [
    for (final priority in TaskPriority.values)
      QuadrantConfigEntity(priority: priority),
  ];

  /// 从持久化的 JSON 列表解析，缺失的象限用默认补齐
  static List<QuadrantConfigEntity> listFromJson(List<dynamic> list) {
    final parsed = <TaskPriority, QuadrantConfigEntity>{};
    for (final item in list) {
      if (item is Map) {
        final entity = QuadrantConfigEntity.fromJson(
          Map<String, dynamic>.from(item),
        );
        parsed[entity.priority] = entity;
      }
    }
    return [
      for (final priority in TaskPriority.values)
        parsed[priority] ?? QuadrantConfigEntity(priority: priority),
    ];
  }
}
