import 'package:flutter/material.dart';
import 'package:flutter_planbook/task/source/model/task_source_panel_type.dart';

/// TaskSourcePanelPickerPage 的返回结果。
///
/// - sourceType 不为 null 时表示用户点击了「确认」并选择了该数据源。
/// - closePanel 为 true 时表示用户点击了「关闭」，需要隐藏 TaskSourcePanel。
@immutable
class TaskSourcePanelPickerResult {
  const TaskSourcePanelPickerResult({
    this.sourceType,
    this.closePanel = false,
  });

  final TaskSourcePanelType? sourceType;
  final bool closePanel;
}
