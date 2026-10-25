import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/view/app_pro_view.dart';
import 'package:flutter_planbook/discover/bookshelf/model/notebook_kind.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_reader_scope.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/diary/view/diary_notebook_theme.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:paper_notebook/paper_notebook.dart';
import 'package:planbook_core/view/flip_page_view.dart';

export '../model/notebook_kind.dart';

class NotebookBookshelf extends StatefulWidget {
  const NotebookBookshelf({
    required this.onOpen,
    required this.onSelected,
    this.selected = NotebookKind.planner,
    this.plannerCoverBuilder,
    this.plannerBackCoverBuilder,
    super.key,
  });

  final ValueChanged<NotebookKind> onOpen;
  final ValueChanged<NotebookKind> onSelected;
  final NotebookKind selected;
  final WidgetBuilder? plannerCoverBuilder;
  final WidgetBuilder? plannerBackCoverBuilder;

  @override
  State<NotebookBookshelf> createState() => NotebookBookshelfState();
}

class NotebookBookshelfState extends State<NotebookBookshelf> {
  final Map<NotebookKind, GlobalKey> _covers = {
    for (final kind in NotebookKind.values) kind: GlobalKey(),
  };

  Rect? coverGlobalRect(NotebookKind kind) => notebookDescendantRect(
    _covers[kind]?.currentContext,
    kind == NotebookKind.planner && widget.plannerCoverBuilder != null
        ? _PlannerCoverPreview.coverKey
        : PaperNotebook.frontCoverKey,
  );
  late final _controller = PageController(
    viewportFraction: 0.84,
    initialPage: widget.selected.index,
  );
  late NotebookKind _selected = widget.selected;

  Future<void> _openNotebook(NotebookKind kind) async {
    // 点到两侧预览时，先将本子移到中间，再量取开书起点。
    if (kind != _selected) {
      await _controller.animateToPage(
        kind.index,
        duration: Durations.medium2,
        curve: Curves.easeInOutCubic,
      );
    }
    if (mounted) widget.onOpen(kind);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 104),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                key: const Key('notebook-bookshelf'),
                controller: _controller,
                itemCount: NotebookKind.values.length,
                onPageChanged: (index) {
                  setState(() => _selected = NotebookKind.values[index]);
                  widget.onSelected(_selected);
                },
                itemBuilder: (context, index) {
                  final kind = NotebookKind.values[index];
                  final title = kind == NotebookKind.planner
                      ? l10n.planbook
                      : l10n.diaryBook;
                  return AnimatedScale(
                    scale: kind == _selected ? 1 : 0.9,
                    duration: Durations.medium2,
                    child: Semantics(
                      button: true,
                      label: '${l10n.openNotebook} · $title',
                      child: GestureDetector(
                        key: ValueKey('notebook-${kind.name}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openNotebook(kind),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: LayoutBuilder(
                            key: _covers[kind],
                            builder: (context, constraints) {
                              if (kind == NotebookKind.planner &&
                                  widget.plannerCoverBuilder != null) {
                                return _PlannerCoverPreview(
                                  coverBuilder: widget.plannerCoverBuilder!,
                                  backCoverBuilder:
                                      widget.plannerBackCoverBuilder ??
                                      widget.plannerCoverBuilder!,
                                );
                              }
                              const format = NotebookFormat.defaults;
                              final coverHeight =
                                  format.frontCoverHeight *
                                  format.fitScale(constraints.biggest);
                              final scale = math.min(
                                1.65,
                                constraints.maxHeight * 0.9 / coverHeight,
                              );
                              return DiaryNotebookThemeBuilder(
                                builder: (year, look) => Transform.scale(
                                  scale: scale,
                                  child: IgnorePointer(
                                    child: PaperNotebook(
                                      pageCount: 1,
                                      gesturesEnabled: false,
                                      coverGesturesEnabled: false,
                                      paperPattern: look.paperPattern,
                                      theme: look.theme(
                                        year: year,
                                        title: title,
                                      ),
                                      pageBuilder: (_, _) =>
                                          const SizedBox.expand(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final kind in NotebookKind.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: Durations.medium1,
                      width: kind == _selected ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: kind == _selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final page = _controller.hasClients
                    ? (_controller.page ?? _selected.index.toDouble())
                    : _selected.index.toDouble();
                return _NotebookShelfCaption(
                  page: page,
                  onOpen: _openNotebook,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 标题、说明和打开按钮跟着书架滑动一起移开，而不是翻页结束后突然替换。
class _NotebookShelfCaption extends StatelessWidget {
  const _NotebookShelfCaption({
    required this.page,
    required this.onOpen,
  });

  final double page;
  final ValueChanged<NotebookKind> onOpen;

  @override
  Widget build(BuildContext context) {
    final travel = MediaQuery.sizeOf(context).width * 0.28;
    return ClipRect(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          for (final kind in NotebookKind.values)
            _page(kind: kind, travel: travel),
        ],
      ),
    );
  }

  Widget _page({required NotebookKind kind, required double travel}) {
    final delta = kind.index - page;
    final opacity = (1 - delta.abs()).clamp(0.0, 1.0);
    final hidden = opacity == 0;
    return Offstage(
      offstage: hidden,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(delta * travel, 0),
          child: IgnorePointer(
            ignoring: delta.abs() > 0.5,
            child: ExcludeSemantics(
              excluding: delta.abs() > 0.5,
              child: _NotebookShelfCaptionPage(
                kind: kind,
                onOpen: () => onOpen(kind),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotebookShelfCaptionPage extends StatelessWidget {
  const _NotebookShelfCaptionPage({
    required this.kind,
    required this.onOpen,
  });

  final NotebookKind kind;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final diary = kind == NotebookKind.diary;
    return Column(
      children: [
        Text(
          diary ? l10n.diaryBook : l10n.planbook,
          style: theme.textTheme.titleLarge,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Text(
            diary ? l10n.diaryBookDescription : l10n.plannerBookDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FilledButton.tonal(
          onPressed: onOpen,
          child: _OpenNotebookLabel(
            title: l10n.openNotebook,
            showProBadge: diary,
          ),
        ),
      ],
    );
  }
}

/// 打开按钮。日记本是 PRO 功能，文案旁带 PRO 标记。
class _OpenNotebookLabel extends StatelessWidget {
  const _OpenNotebookLabel({
    required this.title,
    required this.showProBadge,
  });

  final String title;
  final bool showProBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = _isPremium(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        if (showProBadge) ...[
          const SizedBox(width: 6),
          IgnorePointer(
            child: AppProButton(
              isPremium: isPremium,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 书架测试没有会员 bloc，这时按非会员样式显示。
  bool _isPremium(BuildContext context) {
    try {
      return context.read<AppPurchasesBloc>().state.isPremium;
    } on ProviderNotFoundException {
      return false;
    }
  }
}

/// 计划本的预览与阅读区使用相同的封面及投影，衔接时不会换皮。
class _PlannerCoverPreview extends StatefulWidget {
  const _PlannerCoverPreview({
    required this.coverBuilder,
    required this.backCoverBuilder,
  });

  static const coverKey = Key('planner-shelf-cover');
  final WidgetBuilder coverBuilder;
  final WidgetBuilder backCoverBuilder;

  @override
  State<_PlannerCoverPreview> createState() => _PlannerCoverPreviewState();
}

class _PlannerCoverPreviewState extends State<_PlannerCoverPreview> {
  final _controller = FlipPageController(initialPage: FlipPageIndex.cover);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          1.65,
          constraints.maxHeight / (constraints.maxWidth / 2 * 297 / 210) * 0.9,
        );
        return Transform.scale(
          scale: scale,
          child: IgnorePointer(
            child: FittedBox(
              child: FlipPageView(
                controller: _controller,
                itemsCount: 2,
                pageSize: const Size(
                  kDiscoverJournalDailyPageWidth,
                  kDiscoverJournalDailyPageHeight,
                ),
                borderRadius: BorderRadius.circular(16),
                coverBuilder: (context) => KeyedSubtree(
                  key: _PlannerCoverPreview.coverKey,
                  child: widget.coverBuilder(context),
                ),
                backCoverBuilder: widget.backCoverBuilder,
                itemBuilder: (_, _) => const SizedBox(
                  width: kDiscoverJournalDailyPageWidth,
                  height: kDiscoverJournalDailyPageHeight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
