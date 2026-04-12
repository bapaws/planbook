import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/daily/journal_daily_bloc_manager.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_date_change_view.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_flip_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/gallery/view/note_gallery_calendar_view.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:planbook_core/view/flip_page_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class DiscoverJournalPage extends StatelessWidget {
  const DiscoverJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    return Column(
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
                          DiscoverJournalDateChanged(date: date),
                        );
                      },
                    )
                  : null,
            );
          },
        ),
        const Spacer(),
        BlocSelector<DiscoverJournalBloc, DiscoverJournalState, Jiffy>(
          selector: (state) => state.date,
          builder: (context, date) {
            return DiscoverJournalDateChangeView(
              date: date,
              onDateChanged: (date) {
                context.read<DiscoverJournalBloc>().add(
                  DiscoverJournalDateChanged(date: date),
                );
              },
            );
          },
        ),
        const Spacer(),
        BlocSelector<DiscoverJournalBloc, DiscoverJournalState, int>(
          selector: (state) => state.year,
          builder: (context, year) {
            return RepositoryProvider<JournalDailyBlocManager>(
              key: ValueKey(year),
              create: (context) => JournalDailyBlocManager(
                notesRepository: context.read(),
                tasksRepository: context.read(),
              ),
              dispose: (manager) => manager.dispose(),
              child: const _DiscoverJournalContent(),
            );
          },
        ),
        const Spacer(flex: 3),
        SizedBox(height: query.padding.bottom + kRootBottomBarHeight),
      ],
    );
  }
}

/// Main reading area on the discover-journal tab: owns `FlipPageController`,
/// warms nearby daily blocs, and switches flip / horizontal layouts.
class _DiscoverJournalContent extends StatefulWidget {
  const _DiscoverJournalContent();

  @override
  State<_DiscoverJournalContent> createState() =>
      _DiscoverJournalContentState();
}

class _DiscoverJournalContentState extends State<_DiscoverJournalContent> {
  late final FlipPageController _controller;

  @override
  void initState() {
    super.initState();
    // 初始页面设为 -1，显示封面
    _controller = FlipPageController(
      initialPage: FlipPageIndex.fromLeft(-2),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetch();

      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        final journalDate = context.read<DiscoverJournalBloc>().state.date;
        final startOfYear = journalDate.startOf(Unit.year);
        final page = journalDate.diff(startOfYear, unit: Unit.day).toInt();
        _controller.animateToPage(FlipPageIndex.fromLeft(page * 2));
      });
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowFlipGestureHint(),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _prefetch() {
    if (!mounted) return;
    final journal = context.read<DiscoverJournalBloc>().state;
    context.read<JournalDailyBlocManager>().prefetchDaysAround(
      centerDate: journal.date,
      dayCount: journal.days,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscoverJournalBloc, DiscoverJournalState>(
      listenWhen: (previous, current) => previous.date != current.date,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _prefetch());
      },
      child: DiscoverJournalFlipView(
        controller: _controller,
      ),
    );
  }
}
