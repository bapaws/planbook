import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/journal/day/view/journal_day_page.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/root/journal/bloc/root_journal_bloc.dart';
import 'package:flutter_planbook/root/journal/view/root_journal_drawer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:pull_down_button/pull_down_button.dart';

@RoutePage()
class RootJournalPage extends StatelessWidget {
  const RootJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RootJournalBloc(
        tasksRepository: context.read(),
        notesRepository: context.read(),
        now: Jiffy.now(),
      )..add(const RootJournalRequested()),
      child: const _RootJournalPage(),
    );
  }
}

class _RootJournalPage extends StatefulWidget {
  const _RootJournalPage();

  @override
  State<_RootJournalPage> createState() => _RootJournalPageState();
}

class _RootJournalPageState extends State<_RootJournalPage> {
  late final FlipPageController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    final now = Jiffy.now();
    final startOfYear = now.startOf(Unit.year);
    final page = now.diff(startOfYear, unit: Unit.day).toInt();
    _controller = FlipPageController(initialPage: page);
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final screenSize = MediaQuery.of(context).size;
    final pageWidth = math.min(screenSize.width, screenSize.height) - 32;
    final scale = pageWidth / kJournalPageWidth;
    final pageHeight = kJournalPageHeight * scale;
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const RootJournalDrawer(),
      drawerEdgeDragWidth: 96,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: CupertinoButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          child: const Icon(FontAwesomeIcons.bars),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: BlocBuilder<RootJournalBloc, RootJournalState>(
          buildWhen: (previous, current) => previous.year != current.year,
          builder: (context, state) => AnimatedSwitcher(
            duration: Durations.medium1,
            child: Text(state.year.toString()),
          ),
        ),
        actions: [
          PullDownButton(
            itemBuilder: (context) => [
              PullDownMenuTitle(title: Text(context.l10n.autoPlay)),
              PullDownMenuItem(
                icon: FontAwesomeIcons.calendarMinus,
                title: context.l10n.thisWeek,
                onTap: () {
                  final now = Jiffy.now();
                  final from = now.startOf(Unit.week);
                  final to = now.endOf(Unit.week);
                  _play(from: from, to: to);
                },
              ),
              PullDownMenuItem(
                icon: FontAwesomeIcons.calendarDays,
                title: context.l10n.thisMonth,
                onTap: () {
                  final now = Jiffy.now();
                  final from = now.startOf(Unit.month);
                  final to = now.endOf(Unit.month);
                  _play(from: from, to: to);
                },
              ),
              PullDownMenuItem(
                icon: FontAwesomeIcons.calendar,
                title: context.l10n.thisYear,
                onTap: () {
                  final now = Jiffy.now();
                  final from = now.startOf(Unit.year);
                  final to = now.endOf(Unit.year);
                  _play(from: from, to: to);
                },
              ),
            ],
            buttonBuilder: (context, showMenu) => CupertinoButton(
              onPressed: showMenu,
              child: const Icon(FontAwesomeIcons.ellipsis),
            ),
          ),
        ],
      ),
      body: BlocListener<RootHomeBloc, RootHomeState>(
        listenWhen: (previous, current) =>
            previous.downloadJournalDayCount != current.downloadJournalDayCount,
        listener: (context, state) {
          final year = context.read<RootJournalBloc>().state.year;
          final startOfYear = Jiffy.parseFromList([year]);
          final page = _controller.page;
          if (page == null) return;

          final date = startOfYear.add(days: page);
          _capture(context, date);
        },
        child: Center(
          child: BlocBuilder<RootJournalBloc, RootJournalState>(
            builder: (context, state) {
              final startOfYear = Jiffy.parseFromList([state.year]);
              var initialPage = 0;
              final now = Jiffy.now();
              if (now.year == state.year) {
                initialPage = now.diff(startOfYear, unit: Unit.day).toInt();
              }

              return Container(
                width: pageWidth + 32,
                height: pageHeight + 32,
                margin: EdgeInsets.only(
                  bottom: query.padding.bottom + kRootBottomBarHeight,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FlipPageView(
                  key: ValueKey(state.year),
                  initialPage: initialPage,
                  itemsCount: state.days,
                  controller: _controller,
                  itemBuilder: (context, index) {
                    final date = startOfYear.add(days: index);
                    return FittedBox(
                      key: ValueKey(index),
                      child: JournalDayPage(date: date),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _capture(BuildContext context, Jiffy date) async {
    await EasyLoading.show();
    if (!context.mounted) return;

    try {
      // 使用 controller 截图
      final image = await _controller.captureToImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );

      if (!context.mounted) return;
      if (image == null) {
        await EasyLoading.showError(context.l10n.saveFailed);
        return;
      }

      // 将 ui.Image 转换为 PNG 字节数据
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
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: 'Journal_$dateStr',
      );
      await EasyLoading.dismiss();
      if (!context.mounted) return;

      if (result is Map && result['isSuccess'] == true) {
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
    final fromPage = from.diff(startOfYear, unit: Unit.day).toInt();
    final toPage = to.diff(startOfYear, unit: Unit.day).toInt();
    await _controller.animateToPage(fromPage);

    for (var i = fromPage; i <= toPage; i++) {
      if (!context.mounted) return;
      await _controller.animateToPage(i);
      await Future<void>.delayed(const Duration(milliseconds: 750));
    }
  }
}
