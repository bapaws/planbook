import 'package:collection/collection.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/planbook_api.dart';

/// 在四象限自定义配置列表上按优先级取值的辅助扩展。
///
/// 名称：自定义优先，回退到 l10n 默认名（[TaskPriorityX.getTitle]）。
extension QuadrantConfigListX on List<QuadrantConfigEntity> {
  QuadrantConfigEntity configOf(TaskPriority priority) {
    return firstWhereOrNull((e) => e.priority == priority) ??
        QuadrantConfigEntity(priority: priority);
  }

  String nameOf(TaskPriority priority, AppLocalizations l10n) {
    final name = configOf(priority).name;
    if (name != null && name.isNotEmpty) return name;
    return priority.getTitle(l10n);
  }
}
