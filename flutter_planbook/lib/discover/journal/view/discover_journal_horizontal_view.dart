import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:planbook_core/app/app_image_saver.dart';
import 'package:planbook_repository/planbook_repository.dart';

class DiscoverJournalHorizontalView extends StatefulWidget {
  const DiscoverJournalHorizontalView({required this.initialDate, super.key});

  final Jiffy initialDate;

  @override
  State<DiscoverJournalHorizontalView> createState() =>
      _DiscoverJournalHorizontalViewState();
}

class _DiscoverJournalHorizontalViewState
    extends State<DiscoverJournalHorizontalView> {
  late final PageController _controller;

  /// 程序化滚动（由 BlocListener 触发）时置为 true，避免 onPageChanged 把日期改回当前页
  bool _isAnimating = false;

  /// 自动播放中，listener 不执行 animateToPage，由 _play 的 timer 负责
  bool _isPlaying = false;

  /// 每页一个 GlobalKey，截图时用当前页 index 取 boundary，无需 setState，避免两次刷新。
  /// 仅保留当前页前后各 [_boundaryKeyWindow] 个 index，避免积累大量 key。
  static const int _boundaryKeyWindow = 3;
  final Map<int, GlobalKey> _boundaryKeys = {};

  GlobalKey _boundaryKeyForIndex(int index) {
    final key = _boundaryKeys.putIfAbsent(index, GlobalKey.new);
    if (!_controller.hasClients) return key;
    final current = _controller.page?.round() ?? 0;
    for (final i in _boundaryKeys.keys.toList()) {
      if ((i - current).abs() > _boundaryKeyWindow) _boundaryKeys.remove(i);
    }
    return key;
  }

  @override
  void initState() {
    super.initState();

    final startOfYear = widget.initialDate.startOf(Unit.year);
    final page =
        widget.initialDate.diff(startOfYear, unit: Unit.day).toInt() * 2;
    _controller = PageController(initialPage: page);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final screenSize = MediaQuery.of(context).size;
    var pageWidth = (screenSize.width - 32) * 2;
    final widthScale = pageWidth / kDiscoverJournalDailyPageWidth;
    var pageHeight =
        screenSize.height - query.padding.vertical - kRootBottomBarHeight;
    final heightScale = pageHeight / kDiscoverJournalDailyPageHeight;
    if (widthScale > heightScale) {
      pageWidth = pageWidth * heightScale;
    } else {
      pageHeight = pageHeight * widthScale;
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<RootHomeBloc, RootHomeState>(
          listenWhen: (previous, current) =>
              previous.downloadJournalDayCount !=
              current.downloadJournalDayCount,
          listener: (context, state) {
            _timer?.cancel();
            _timer = null;

            final page = _controller.page?.toInt();
            if (page == null) return;

            final year = context.read<DiscoverJournalBloc>().state.year;
            final startOfYear = Jiffy.parseFromList([year]);
            final date = startOfYear.add(days: page ~/ 2);
            _capture(context, date, pageIndex: page);
          },
        ),
        BlocListener<RootDiscoverBloc, RootDiscoverState>(
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
        ),
      ],
      child: BlocConsumer<DiscoverJournalBloc, DiscoverJournalState>(
        listenWhen: (previous, current) => previous.date != current.date,
        listener: (context, state) {
          if (_isPlaying) return;

          final startOfYear = state.date.startOf(Unit.year);
          final targetPage =
              state.date.diff(startOfYear, unit: Unit.day).toInt() * 2;
          final currentPage = _controller.hasClients
              ? (_controller.page?.round() ?? 0)
              : 0;
          // 当前页已是该日期的左半或右半时不再滚，避免用户左滑后 listener 再滚一页造成“连滑两页”
          if (currentPage == targetPage || currentPage == targetPage + 1) {
            return;
          }

          _isAnimating = true;
          _controller
              .animateToPage(
                targetPage,
                duration: Durations.medium1,
                curve: Curves.easeInOut,
              )
              .whenComplete(() {
                if (mounted) _isAnimating = false;
              });
        },
        buildWhen: (previous, current) => previous.year != current.year,
        builder: (context, state) {
          final startOfYear = state.date.startOf(Unit.year);
          return SizedBox(
            width: screenSize.width,
            height: pageHeight,
            // clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: pageWidth,
              height: pageHeight,
              child: PageView.builder(
                controller: _controller,
                itemCount: state.days * 2,
                itemBuilder: (context, index) {
                  final date = startOfYear.add(days: index ~/ 2);
                  return FittedBox(
                    child: RepaintBoundary(
                      key: _boundaryKeyForIndex(index),
                      child: index.isEven
                          ? JournalDailyLeftPage(
                              date: date,
                              key: ValueKey(index),
                            )
                          : JournalDailyRightPage(
                              date: date,
                              key: ValueKey(index),
                            ),
                    ),
                  );
                },
                onPageChanged: (index) {
                  if (_isAnimating) return;
                  final date = startOfYear.add(days: index ~/ 2);
                  context.read<DiscoverJournalBloc>().add(
                    DiscoverJournalDateChanged(date: date),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _capture(
    BuildContext context,
    Jiffy date, {
    required int pageIndex,
  }) async {
    await EasyLoading.show();
    if (!context.mounted) return;

    try {
      final boundary =
          _boundaryKeys[pageIndex]?.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        await EasyLoading.showError(context.l10n.saveFailed);
        return;
      }

      final image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );

      if (!context.mounted) return;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!context.mounted) return;
      if (byteData == null) {
        await EasyLoading.showError(context.l10n.saveFailed);
        return;
      }

      final imageBytes = byteData.buffer.asUint8List();

      final dateStr =
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.date.toString().padLeft(2, '0')}';
      final result = await AppImageSaver.saveImage(
        imageBytes,
        fileName: 'Journal_$dateStr',
      );
      await EasyLoading.dismiss();
      if (!context.mounted) return;

      if (result.isSuccess) {
        await EasyLoading.showSuccess(context.l10n.saveSuccess);
      } else {
        await EasyLoading.showError(context.l10n.saveFailed);
      }
    } on Exception catch (_) {
      await EasyLoading.dismiss();

      if (!context.mounted) return;
      await EasyLoading.showError(context.l10n.saveFailed);
    }
  }

  Future<void> _play({
    required Jiffy from,
    required Jiffy to,
  }) async {
    final startOfYear = from.startOf(Unit.year);
    final fromDay = from.diff(startOfYear, unit: Unit.day).toInt();
    final toDay = to.diff(startOfYear, unit: Unit.day).toInt();
    final fromPage = fromDay * 2;
    final toPage = toDay * 2 + 1;

    if (!mounted) return;
    _isPlaying = true;
    context.read<DiscoverJournalBloc>().add(
      DiscoverJournalDateChanged(date: from),
    );
    await _controller.animateToPage(
      fromPage,
      duration: Durations.medium1,
      curve: Curves.easeInOut,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final page = fromPage + timer.tick;
      if (page > toPage) {
        timer.cancel();
        if (mounted) _isPlaying = false;
        return;
      }
      final date = startOfYear.add(days: page ~/ 2);
      context.read<DiscoverJournalBloc>().add(
        DiscoverJournalDateChanged(date: date),
      );
      _isAnimating = true;
      _controller
          .animateToPage(
            page,
            duration: Durations.medium1,
            curve: Curves.easeInOut,
          )
          .whenComplete(() {
            if (mounted) _isAnimating = false;
          });
    });
  }
}
