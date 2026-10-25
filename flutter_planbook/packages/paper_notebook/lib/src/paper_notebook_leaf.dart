import 'package:flutter/material.dart';
import 'package:paper_notebook/src/paper_notebook_cover_style.dart';
import 'package:paper_notebook/src/paper_notebook_scope.dart';
import 'package:paper_notebook/src/paper_notebook_surface.dart';

/// 默认上页眉：种类 + 标题 + 副标题。
class PaperNotebookLeafHeader extends StatelessWidget {
  const PaperNotebookLeafHeader({
    required this.kindLabel,
    required this.title,
    this.subtitle,
    super.key,
  });

  final String kindLabel;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              PaperNotebookCoverColors.brandImprint(kindLabel),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (subtitle != null)
            Expanded(
              child: Center(
                child: Text(
                  subtitle!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(title, style: theme.textTheme.titleSmall),
            ),
          ),
        ],
      ),
    );
  }
}

/// 内页脚手架：纸纹 + 书脊阴影；上页眉 / 中间内容 / 下页脚。
///
/// 页眉、页脚钉在纸张上下，不随中间区域滚动。
class PaperNotebookLeaf extends StatelessWidget {
  const PaperNotebookLeaf({
    this.header,
    this.footer,
    this.body,
    this.kindLabel,
    this.title,
    this.subtitle,
    this.sliver,
    this.slivers = const [],
    super.key,
  });

  /// 上页眉。传入后不再用 [kindLabel] / [title] / [subtitle]。
  final Widget? header;

  /// 下页脚，钉在纸张底部。
  final Widget? footer;

  /// 中间区域。不传则用 [sliver] / [slivers] 做成可滚动区。
  final Widget? body;

  final String? kindLabel;
  final String? title;
  final String? subtitle;

  /// 中间滚动区的单个 sliver。
  final Widget? sliver;

  /// 中间滚动区的多个 sliver，可与 [sliver] 同时用。
  final List<Widget> slivers;

  Widget? get _resolvedHeader {
    if (header != null) return header;
    if (kindLabel == null || title == null) return null;
    return PaperNotebookLeafHeader(
      kindLabel: kindLabel!,
      title: title!,
      subtitle: subtitle,
    );
  }

  Widget get _resolvedBody {
    if (body != null) return body!;
    return CustomScrollView(
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [...slivers, if (sliver != null) sliver!],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final spine = dark
        ? const [Color(0x59000000), Color(0x24000000), Color(0x00000000)]
        : const [Color(0x40000000), Color(0x14000000), Color(0x00000000)];
    final top = _resolvedHeader;
    final showSpine = PaperNotebookScope.showSpineShadowOf(context);
    return PaperNotebookSurface(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showSpine)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 28,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: spine,
                      stops: const [0, 0.35, 1],
                    ),
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (top != null) top,
              Expanded(child: _resolvedBody),
              if (footer != null) footer!,
            ],
          ),
        ],
      ),
    );
  }
}
