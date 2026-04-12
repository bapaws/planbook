import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:planbook_core/view/flip_page_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 日记封面
class _JournalCover extends StatelessWidget {
  const _JournalCover({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const w = kDiscoverJournalDailyPageWidth / 2;
    const h = kDiscoverJournalDailyPageHeight;

    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(16),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(cs.primaryContainer, cs.surface, 0.35)!,
              cs.surfaceContainerHigh,
            ],
          ),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$year',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '日记',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '往左滑打开',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 日记封底
class _JournalBackCover extends StatelessWidget {
  const _JournalBackCover({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const w = kDiscoverJournalDailyPageWidth / 2;
    const h = kDiscoverJournalDailyPageHeight;

    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(16),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surfaceContainerHigh,
              Color.lerp(cs.primaryContainer, cs.surface, 0.35)!,
            ],
          ),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 48,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  '$year',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '记录每一天',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DiscoverJournalFlipView extends StatefulWidget {
  const DiscoverJournalFlipView({required this.controller, super.key});

  final FlipPageController controller;

  @override
  State<DiscoverJournalFlipView> createState() =>
      _DiscoverJournalFlipViewState();
}

class _DiscoverJournalFlipViewState extends State<DiscoverJournalFlipView> {
  FlipPageController get _controller => widget.controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onFlipPageChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onFlipPageChanged);
    super.dispose();
  }

  void _onFlipPageChanged() {
    final index = _controller.value;
    // 封面索引为 -1，不触发日期变化
    if (!_controller.isContentPage(index)) return;

    final bloc = context.read<DiscoverJournalBloc>();
    final startOfYear = bloc.state.date.startOf(
      Unit.year,
    );
    final date = startOfYear.add(days: index.left ~/ 2);
    bloc.add(DiscoverJournalDateChanged(date: date));
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    var scale = 1.0;
    var pageWidth = screenSize.width - 32;
    var pageHeight =
        screenSize.height - query.padding.vertical - kRootBottomBarHeight;
    if (isLandscape) {
      pageHeight =
          (screenSize.height - query.padding.vertical - kRootBottomBarHeight) *
          0.6;
      scale = pageHeight / kDiscoverJournalDailyPageHeight;
      pageWidth = kDiscoverJournalDailyPageWidth * scale;
    } else {
      pageWidth = screenSize.width - query.padding.horizontal - 32;
      scale = pageWidth / kDiscoverJournalDailyPageWidth;
      pageHeight = kDiscoverJournalDailyPageHeight * scale;
    }

    return BlocListener<RootDiscoverBloc, RootDiscoverState>(
      listenWhen: (previous, current) =>
          previous.autoPlayCount != current.autoPlayCount,
      listener: (context, state) async {
        final result = await context.router.push<Map<String, dynamic>>(
          const DiscoverJournalPlayRoute(),
        );
        if (result == null) return;

        final from = result['from'];
        final to = result['to'];
        if (from != null && from is Jiffy && to != null && to is Jiffy) {
          await _play(from: from, to: to);
        }
      },
      child: BlocConsumer<DiscoverJournalBloc, DiscoverJournalState>(
        listenWhen: (previous, current) =>
            previous.date.year != current.date.year,
        listener: (context, state) {
          _timer?.cancel();
          _timer = null;

          final startOfYear = state.date.startOf(Unit.year);
          final page = state.date.diff(startOfYear, unit: Unit.day).toInt();
          // 跳转到对应的内容页（索引从 0 开始）
          _controller.jumpToPage(FlipPageIndex.fromLeft(page));
        },
        buildWhen: (previous, current) => previous.year != current.year,
        builder: (context, state) {
          final startOfYear = state.date.startOf(Unit.year);
          return Container(
            width: pageWidth + 32,
            height: pageHeight + 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FittedBox(
              child: FlipPageView(
                itemsCount: state.days * 2,
                controller: _controller,
                pageSize: const Size(
                  kDiscoverJournalDailyPageWidth / 2,
                  kDiscoverJournalDailyPageHeight,
                ),
                spacing: 1,
                borderRadius: BorderRadius.circular(16),
                coverBuilder: (context) => _JournalCover(year: state.year),
                backCoverBuilder: (context) =>
                    _JournalBackCover(year: state.year),
                itemBuilder: (context, index) {
                  final date = startOfYear.add(days: index ~/ 2);
                  if (index.isEven) {
                    return JournalDailyLeftPage(date: date);
                  }
                  return JournalDailyRightPage(date: date);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _play({
    required Jiffy from,
    required Jiffy to,
  }) async {
    final startOfYear = from.startOf(Unit.year);
    final fromPage = from.diff(startOfYear, unit: Unit.day).toInt();
    final toPage = to.diff(startOfYear, unit: Unit.day).toInt();
    await _controller.animateToPage(FlipPageIndex.fromLeft(fromPage));

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!context.mounted) return;
      final page = fromPage + timer.tick;
      if (page > toPage) {
        timer.cancel();
        return;
      }
      _controller.animateToPage(FlipPageIndex.fromLeft(page));
    });
  }
}
