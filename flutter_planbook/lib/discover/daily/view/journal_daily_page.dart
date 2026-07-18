import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/discover/daily/bloc/journal_daily_bloc.dart';
import 'package:flutter_planbook/discover/daily/journal_daily_bloc_manager.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_data_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_date_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_focus_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_note_grid_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_timeline_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

const double kDiscoverJournalDailyPageWidth = 210 * 2.5;
const double kDiscoverJournalDailyPageHeight = 297 * 2.5;

const double kJournalPageSpacing = 16;

/// 与日记半页/全页统一的页面背景容器。
/// 使用 AppBloc 中的 book 背景资源，和日记页保持一致。
class JournalPage extends StatelessWidget {
  const JournalPage({
    required this.child,
    this.width = kDiscoverJournalDailyPageWidth,
    this.height = kDiscoverJournalDailyPageHeight,
    this.padding = const EdgeInsets.all(kJournalPageSpacing),
    super.key,
  });

  final Widget child;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocSelector<AppBloc, AppState, AppBackgroundEntity?>(
      selector: (state) => state.background,
      builder: (context, background) {
        return Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                theme.brightness == Brightness.light
                    ? background?.bookLightAsset ??
                          'assets/tiles/bg_dot_light.png'
                    : background?.bookDarkAsset ??
                          'assets/tiles/bg_dot_dark.png',
              ),
              scale: 3,
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

@RoutePage()
class JournalDailyPage extends StatelessWidget {
  const JournalDailyPage({required this.date, super.key});

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => JournalDailyBloc(
        date: date,
        notesRepository: context.read(),
        tasksRepository: context.read(),
      )..requestAll(),
      child: const _JournalDailyFullPage(),
    );
  }
}

/// Left half page; requires `JournalDailyBlocManager` from
/// `RepositoryProvider` above (journal tab).
class JournalDailyLeftPage extends StatelessWidget {
  const JournalDailyLeftPage({
    required this.date,
    super.key,
  });

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<JournalDailyBlocManager>().blocForDay(date: date);
    return BlocProvider.value(
      value: bloc,
      child: const _JournalDailyHalfPage(
        child: _JournalDailyLeftContent(),
      ),
    );
  }
}

/// Right half page; shares the same bloc as `JournalDailyLeftPage` for the
/// same calendar `date` when using `JournalDailyBlocManager`.
class JournalDailyRightPage extends StatelessWidget {
  const JournalDailyRightPage({
    required this.date,
    super.key,
  });

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<JournalDailyBlocManager>().blocForDay(date: date);
    return BlocProvider.value(
      value: bloc,
      child: const _JournalDailyHalfPage(
        child: _JournalDailyRightContent(),
      ),
    );
  }
}

class _JournalDailyFullPage extends StatelessWidget {
  const _JournalDailyFullPage();

  @override
  Widget build(BuildContext context) {
    return const JournalPage(
      width: kDiscoverJournalDailyPageWidth * 2,
      child: Row(
        children: [
          _JournalDailyLeftContent(),
          SizedBox(width: kJournalPageSpacing * 2 - 2),
          _JournalDailyRightContent(),
        ],
      ),
    );
  }
}

class _JournalDailyHalfPage extends StatelessWidget {
  const _JournalDailyHalfPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return JournalPage(child: child);
  }
}

class _JournalDailyLeftContent extends StatelessWidget {
  const _JournalDailyLeftContent();

  @override
  Widget build(BuildContext context) {
    final date = context.read<JournalDailyBloc>().date;
    final colWidth =
        ((kDiscoverJournalDailyPageWidth - kJournalPageSpacing * 3) / 2)
            .floorToDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              JournalDailyDateView(date: date),
              const SizedBox(height: kJournalPageSpacing),
              const JournalDailyDataView(),
              const Spacer(),
              Flexible(
                child: BlocSelector<JournalDailyBloc, JournalDailyState, Note?>(
                  selector: (state) => state.focusNote,
                  builder: (context, focusNote) => JournalDailyFocusView(
                    note: focusNote,
                    noteType: NoteType.dailyFocus,
                    colorScheme: context.yellowColorScheme,
                  ),
                ),
              ),
              const SizedBox(height: kJournalPageSpacing),
              Flexible(
                child: BlocSelector<JournalDailyBloc, JournalDailyState, Note?>(
                  selector: (state) => state.summaryNote,
                  builder: (context, focusNote) => JournalDailyFocusView(
                    note: focusNote,
                    noteType: NoteType.dailySummary,
                    colorScheme: context.blueColorScheme,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: kJournalPageSpacing),
        SizedBox(
          width: colWidth,
          height: kDiscoverJournalDailyPageHeight - 32,
          child: const JournalDailyTimelineView(),
        ),
      ],
    );
  }
}

class _JournalDailyRightContent extends StatelessWidget {
  const _JournalDailyRightContent();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kDiscoverJournalDailyPageWidth - kJournalPageSpacing * 2,
      height: kDiscoverJournalDailyPageHeight - 32,
      child:
          BlocSelector<JournalDailyBloc, JournalDailyState, List<NoteEntity>>(
            selector: (state) => state.writtenNotes,
            builder: (context, notes) => JournalDailyNoteGridView(
              notes: notes,
              width: kDiscoverJournalDailyPageWidth - kJournalPageSpacing * 2,
            ),
          ),
    );
  }
}
