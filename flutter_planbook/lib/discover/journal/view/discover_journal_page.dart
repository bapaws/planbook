import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/gallery/view/note_gallery_calendar_view.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_core/app/app_image_saver.dart';
import 'package:planbook_core/view/flip_page_view.dart';

@RoutePage()
class DiscoverJournalPage extends StatefulWidget {
  const DiscoverJournalPage({super.key});

  @override
  State<DiscoverJournalPage> createState() => _DiscoverJournalPageState();
}

class _DiscoverJournalPageState extends State<DiscoverJournalPage> {
  late final FlipPageController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Timer? _timer;

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
    final theme = Theme.of(context);
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
    return MultiBlocListener(
      listeners: [
        BlocListener<RootHomeBloc, RootHomeState>(
          listenWhen: (previous, current) =>
              previous.downloadJournalDayCount !=
              current.downloadJournalDayCount,
          listener: (context, state) {
            _timer?.cancel();
            _timer = null;

            final year = context.read<DiscoverJournalBloc>().state.year;
            final startOfYear = Jiffy.parseFromList([year]);
            final date = startOfYear.add(days: _controller.value);
            _capture(context, date);
          },
        ),
        BlocListener<DiscoverJournalBloc, DiscoverJournalState>(
          listenWhen: (previous, current) =>
              previous.date.year != current.date.year,
          listener: (context, state) {
            _timer?.cancel();
            _timer = null;

            final startOfYear = state.date.startOf(Unit.year);
            final page = state.date.diff(startOfYear, unit: Unit.day).toInt();
            _controller.jumpToPage(page);
          },
        ),
        BlocListener<RootDiscoverBloc, RootDiscoverState>(
          listenWhen: (previous, current) =>
              previous.autoPlayFrom != current.autoPlayFrom ||
              previous.autoPlayTo != current.autoPlayTo,
          listener: (context, state) {
            if (state.autoPlayFrom == null || state.autoPlayTo == null) return;
            _play(from: state.autoPlayFrom!, to: state.autoPlayTo!);
          },
        ),
      ],
      child: Column(
        children: [
          BlocSelector<DiscoverJournalBloc, DiscoverJournalState, bool>(
            selector: (state) => state.isCalendarExpanded,
            builder: (context, isCalendarExpanded) {
              return AnimatedSwitcher(
                duration: Durations.medium1,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    child: child,
                  ),
                ),
                child: isCalendarExpanded
                    ? NoteGalleryCalendarView(
                        date: context.read<DiscoverJournalBloc>().state.date,
                        onDateSelected: (date) {
                          context.read<DiscoverJournalBloc>().add(
                            JournalHomeYearChanged(date: date),
                          );
                        },
                      )
                    : null,
              );
            },
          ),
          const Spacer(),
          BlocBuilder<DiscoverJournalBloc, DiscoverJournalState>(
            buildWhen: (previous, current) => previous.year != current.year,
            builder: (context, state) {
              final startOfYear = state.date.startOf(Unit.year);
              return Container(
                width: pageWidth + 32,
                height: pageHeight + 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                // clipBehavior: Clip.hardEdge,
                child: FittedBox(
                  child: FlipPageView(
                    // key: ValueKey(state.year),
                    itemsCount: state.days,
                    controller: _controller,
                    itemBuilder: (context, index) {
                      final date = startOfYear.add(days: index);
                      return JournalDailyPage(date: date);
                    },
                  ),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                minimumSize: const Size.square(kMinInteractiveDimension),
                onPressed: () {
                  _controller.animateToPage(_controller.value - 1);
                },
                child: const Icon(FontAwesomeIcons.chevronLeft, size: 16),
              ),
              SizedBox(
                width: 72,
                height: kMinInteractiveDimension,
                child: Center(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _controller,
                    builder: (context, page, child) {
                      final date = context
                          .read<DiscoverJournalBloc>()
                          .state
                          .date;
                      return Text(
                        date.startOf(Unit.year).add(days: page).MMMd,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      );
                    },
                  ),
                ),
              ),
              CupertinoButton(
                minimumSize: const Size.square(kMinInteractiveDimension),
                onPressed: () {
                  _controller.animateToPage(_controller.value + 1);
                },
                child: const Icon(FontAwesomeIcons.chevronRight, size: 16),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(height: query.padding.bottom + kRootBottomBarHeight),
        ],
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
