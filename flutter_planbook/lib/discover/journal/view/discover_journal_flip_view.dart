import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:planbook_core/view/flip_page_view.dart';

class DiscoverJournalFlipView extends StatefulWidget {
  const DiscoverJournalFlipView({
    required this.itemsCount,
    required this.itemBuilder,
    required this.onPageChanged,
    required this.controller,
    required this.coverBuilder,
    required this.backCoverBuilder,
    this.initialPage = FlipPageIndex.cover,
    super.key,
  });

  final FlipPageIndex initialPage;
  final ValueChanged<FlipPageIndex> onPageChanged;

  final int itemsCount;
  final IndexedWidgetBuilder itemBuilder;
  final FlipPageController controller;

  /// 封面构建器，当在第一页往右滑时显示
  final WidgetBuilder coverBuilder;

  /// 封底构建器，当在最后一页往左滑时显示
  final WidgetBuilder backCoverBuilder;

  @override
  State<DiscoverJournalFlipView> createState() =>
      _DiscoverJournalFlipViewState();
}

class _DiscoverJournalFlipViewState extends State<DiscoverJournalFlipView> {
  FlipPageController get _controller => widget.controller;

  bool _isLeftEnlarged = false;
  bool _isRightEnlarged = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onFlipPageChanged);

    if (widget.initialPage != FlipPageIndex.cover) {
      _controller.animateToPage(FlipPageIndex.cover);
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _controller.animateToPage(widget.initialPage);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onFlipPageChanged);
    super.dispose();
  }

  void _onFlipPageChanged() {
    final index = _controller.value;
    if (_controller.isCoverPage(index) || _controller.isBackCoverPage(index)) {
      _isLeftEnlarged = false;
      _isRightEnlarged = false;
      return;
    }

    // 封面索引为 -1，不触发日期变化
    if (!_controller.isContentPage(index)) return;
    widget.onPageChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final pageWidth = screenSize.width - query.padding.horizontal - 32;
    final pageHeight = min(
      screenSize.height -
          query.padding.vertical -
          kToolbarHeight -
          kRootBottomBarHeight -
          16 -
          kMinInteractiveDimension * 3,
      pageWidth /
              kDiscoverJournalDailyPageWidth *
              kDiscoverJournalDailyPageHeight -
          32,
    );

    final isEnlarged = _isLeftEnlarged || _isRightEnlarged;

    var enlargedAlignment = Alignment.center;
    if (_isLeftEnlarged) {
      enlargedAlignment = Alignment.centerLeft;
    } else if (_isRightEnlarged) {
      enlargedAlignment = Alignment.centerRight;
    }

    // fitHeight / contain 的缩放比
    final containerW = pageWidth + 8;
    const bookW = kDiscoverJournalDailyPageWidth * 2 + 3.0;
    final enlargedRatio = isLandscape
        ? 1
        : (pageHeight / kDiscoverJournalDailyPageHeight) / (containerW / bookW);

    return Container(
      width: pageWidth + 32,
      height: pageHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          end: isEnlarged ? 1.0 : 0.0,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (context, t, child) {
          return Transform.scale(
            scale: 1.0 + (enlargedRatio - 1.0) * t,
            alignment: Alignment.lerp(
              Alignment.center,
              enlargedAlignment,
              t,
            ),
            child: child,
          );
        },
        child: FittedBox(
          child: FlipPageView(
            itemsCount: widget.itemsCount,
            controller: _controller,
            pageSize: const Size(
              kDiscoverJournalDailyPageWidth,
              kDiscoverJournalDailyPageHeight,
            ),
            spacing: 1,
            borderRadius: BorderRadius.circular(16),
            coverBuilder: widget.coverBuilder,
            backCoverBuilder: widget.backCoverBuilder,
            itemBuilder: widget.itemBuilder,
            onLeftDoubleTap: (index) {
              context.read<DiscoverJournalBloc>().add(
                const DiscoverJournalLeftEnlargedToggled(),
              );
            },
            onRightDoubleTap: (index) {
              context.read<DiscoverJournalBloc>().add(
                const DiscoverJournalRightEnlargedToggled(),
              );
            },
          ),
        ),
      ),
    );
  }
}
