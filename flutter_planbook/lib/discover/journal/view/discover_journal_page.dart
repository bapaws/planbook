import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/daily/journal_daily_bloc_manager.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/discover/journal/model/journal_date.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_cover.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_date_change_view.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_flip_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/gallery/view/note_gallery_calendar_view.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/flip_page_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class DiscoverJournalPage extends StatefulWidget {
  const DiscoverJournalPage({super.key});

  @override
  State<DiscoverJournalPage> createState() => _DiscoverJournalPageState();
}

class _DiscoverJournalPageState extends State<DiscoverJournalPage> {
  final FlipPageController _controller = FlipPageController(
    initialPage: FlipPageIndex.cover,
  );

  late final _blocManager = JournalDailyBlocManager(
    notesRepository: context.read(),
    tasksRepository: context.read(),
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetch();

      _maybeShowFlipGestureHint();
    });
  }

  @override
  void dispose() {
    _blocManager.dispose();
    super.dispose();
  }

  void _prefetch() {
    if (!mounted) return;
    final journalDate = context.read<DiscoverJournalBloc>().state.date;
    _blocManager.prefetchDaysAround(
      centerDate: journalDate.date,
      dayCount: journalDate.daysInYear,
    );
  }

  /// 首次进入日志翻页模式时提示手势；关闭对话框后写入本地标记。
  Future<void> _maybeShowFlipGestureHint() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final settings = context.read<SettingsRepository>();
    if (settings.getDiscoverJournalFlipGestureHintShown()) return;
    final l10n = context.l10n;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.discoverJournalFlipGestureHintTitle),
        content: SingleChildScrollView(
          child: Text(l10n.discoverJournalFlipGestureHintMessage),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.iKnow),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await settings.setDiscoverJournalFlipGestureHintShown(shown: true);
  }

  Future<void> _play({
    required Jiffy from,
    required Jiffy to,
  }) async {
    final startOfYear = from.startOf(Unit.year);
    final fromPage = from.diff(startOfYear, unit: Unit.day).toInt() * 2;
    final toPage = to.diff(startOfYear, unit: Unit.day).toInt() * 2;
    await _controller.animateToPage(FlipPageIndex.fromLeft(fromPage));

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_controller.hasClients) {
        timer.cancel();
        return;
      }

      final page = fromPage + timer.tick * 2;
      if (page > toPage) {
        timer.cancel();
        return;
      }
      _controller.animateToPage(FlipPageIndex.fromLeft(page));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DiscoverJournalBloc, DiscoverJournalState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == PageStatus.loading) {
              EasyLoading.show();
            } else {
              EasyLoading.dismiss();
            }
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
        BlocListener<DiscoverJournalBloc, DiscoverJournalState>(
          listenWhen: (previous, current) => previous.date != current.date,
          listener: (context, state) {
            _controller.animateToPage(state.date.pageIndex);
          },
        ),
      ],
      child: RepositoryProvider.value(
        value: _blocManager,
        child: _DiscoverJournalPage(
          controller: _controller,
        ),
      ),
    );
  }
}

class _DiscoverJournalPage extends StatelessWidget {
  const _DiscoverJournalPage({
    required this.controller,
  });

  final FlipPageController controller;

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.read<DiscoverJournalBloc>().add(
          const DiscoverJournalCalendarToggled(isExpanded: false),
        );
      },
      child: Stack(
        children: [
          Column(
            children: [
              BlocBuilder<DiscoverJournalBloc, DiscoverJournalState>(
                buildWhen: (previous, current) => previous.date != current.date,
                builder: (context, state) {
                  return DiscoverJournalDateChangeView(
                    date: state.date,
                    onDateChanged: (date) {
                      context.read<DiscoverJournalBloc>().add(
                        DiscoverJournalDateChanged(date: date),
                      );
                    },
                  );
                },
              ),
              const Spacer(),
              _DiscoverJournalContent(controller: controller),
              const Spacer(),
              SizedBox(
                height: query.padding.bottom + kRootBottomBarHeight + 16,
              ),
            ],
          ),
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
                        date: context
                            .read<DiscoverJournalBloc>()
                            .state
                            .date
                            .date,
                        onDateSelected: (date) {
                          context.read<DiscoverJournalBloc>().add(
                            DiscoverJournalYearChanged(year: date.year),
                          );
                        },
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Main reading area on the discover-journal tab: owns `FlipPageController`,
/// warms nearby daily blocs, and switches flip / horizontal layouts.
class _DiscoverJournalContent extends StatelessWidget {
  const _DiscoverJournalContent({
    required this.controller,
  });

  final FlipPageController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoverJournalBloc, DiscoverJournalState>(
      buildWhen: (previous, current) =>
          previous.date.year != current.date.year ||
          previous.coverBackgroundImage != current.coverBackgroundImage ||
          previous.coverColorScheme != current.coverColorScheme,
      builder: (context, state) => AnimatedSwitcher(
        duration: Durations.medium1,
        child: state.coverBackgroundImage == null
            ? const SizedBox.shrink()
            : DiscoverJournalFlipView(
                initialPage: state.date.pageIndex,
                coverBuilder: (context) => JournalCover(
                  year: state.date.year,
                  backgroundImage: state.coverBackgroundImage,
                  colorScheme: state.coverColorScheme,
                ),
                backCoverBuilder: (context) => JournalBackCover(
                  year: state.date.year,
                  backgroundImage: state.coverBackgroundImage,
                  colorScheme: state.coverColorScheme,
                ),
                onPageChanged: (index) {
                  final journalDate = context
                      .read<DiscoverJournalBloc>()
                      .state
                      .date;
                  if (index == journalDate.pageIndex) return;
                  context.read<DiscoverJournalBloc>().add(
                    DiscoverJournalDateChanged(
                      date: JournalDate.fromYear(
                        journalDate.year,
                        pageIndex: index,
                      ),
                    ),
                  );
                },
                controller: controller,
                itemsCount: state.date.daysInYear * 2,
                itemBuilder: (context, index) {
                  final date = state.date.startOfYear.add(days: index ~/ 2);
                  if (index.isEven) {
                    return JournalDailyLeftPage(date: date);
                  }
                  return JournalDailyRightPage(date: date);
                },
              ),
      ),
    );
  }
}
