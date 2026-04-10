import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:planbook_core/view/flip_page_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

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
    final bloc = context.read<DiscoverJournalBloc>();
    final startOfYear = bloc.state.date.startOf(
      Unit.year,
    );
    final date = startOfYear.add(days: index);
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
          _controller.jumpToPage(page);
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
                spacing: 1,
                borderRadius: BorderRadius.circular(16),
                itemBuilder: (context, index) {
                  final date = startOfYear.add(days: index ~/ 2);
                  if (index.isOdd) {
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
    await _controller.animateToPage(fromPage);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!context.mounted) return;
      final page = fromPage + timer.tick;
      if (page > toPage) {
        timer.cancel();
        return;
      }
      _controller.animateToPage(page);
    });
  }
}
