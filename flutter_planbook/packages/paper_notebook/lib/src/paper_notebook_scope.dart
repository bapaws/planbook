import 'package:flutter/material.dart';
import 'package:paper_notebook/src/layout/notebook_format.dart';
import 'package:paper_notebook/src/paper_notebook_pattern.dart';
import 'package:paper_notebook/src/paper_notebook_style.dart';
import 'package:paper_notebook/src/paper_notebook_theme.dart';

/// 向引擎下传 style / theme / 纸纹。
class PaperNotebookScope extends InheritedWidget {
  const PaperNotebookScope({
    required this.format,
    required this.theme,
    required this.pattern,
    this.showSpineShadow = true,
    required super.child,
    super.key,
  });

  final NotebookFormat format;
  final PaperNotebookTheme theme;
  final PaperNotebookPattern pattern;

  /// 书脊侧渐变；导出预览可关，阅读器默认开。
  final bool showSpineShadow;

  PaperNotebookStyle get style => format.style;

  static PaperNotebookScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PaperNotebookScope>();
    assert(scope != null, 'PaperNotebookScope not found');
    return scope!;
  }

  static PaperNotebookScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PaperNotebookScope>();
  }

  static NotebookFormat formatOf(BuildContext context) {
    return maybeOf(context)?.format ?? NotebookFormat.defaults;
  }

  static PaperNotebookStyle styleOf(BuildContext context) {
    return formatOf(context).style;
  }

  static PaperNotebookTheme themeOf(BuildContext context) {
    return maybeOf(context)?.theme ?? PaperNotebookTheme.defaults;
  }

  static PaperNotebookPattern patternOf(BuildContext context) {
    return maybeOf(context)?.pattern ?? PaperNotebookPattern.dots;
  }

  static bool showSpineShadowOf(BuildContext context) {
    return maybeOf(context)?.showSpineShadow ?? true;
  }

  @override
  bool updateShouldNotify(covariant PaperNotebookScope oldWidget) {
    return format != oldWidget.format ||
        theme != oldWidget.theme ||
        pattern != oldWidget.pattern ||
        showSpineShadow != oldWidget.showSpineShadow;
  }
}
