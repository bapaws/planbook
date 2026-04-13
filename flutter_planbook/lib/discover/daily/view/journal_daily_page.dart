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

const double _spacing = 16;

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
        isLeft: false,
        child: _JournalDailyRightContent(),
      ),
    );
  }
}

class _JournalDailyFullPage extends StatelessWidget {
  const _JournalDailyFullPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocSelector<AppBloc, AppState, AppBackgroundEntity?>(
      selector: (state) => state.background,
      builder: (context, background) {
        return Container(
          width: kDiscoverJournalDailyPageWidth * 2,
          height: kDiscoverJournalDailyPageHeight,
          padding: const EdgeInsets.all(_spacing),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            borderRadius: BorderRadius.circular(24),
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
          child: const Row(
            children: [
              _JournalDailyLeftContent(),
              SizedBox(width: _spacing * 2 - 2),
              _JournalDailyRightContent(),
            ],
          ),
        );
      },
    );
  }
}

class _JournalDailyHalfPage extends StatelessWidget {
  const _JournalDailyHalfPage({required this.child, this.isLeft = true});

  final Widget child;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocSelector<AppBloc, AppState, AppBackgroundEntity?>(
      selector: (state) => state.background,
      builder: (context, background) {
        return Container(
          width: kDiscoverJournalDailyPageWidth,
          height: kDiscoverJournalDailyPageHeight,
          padding: const EdgeInsets.all(_spacing),
          // clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            // color: theme.colorScheme.surfaceContainerLowest,
            // border: Border(
            //   left: isLeft
            //       ? BorderSide(
            //           color: theme.colorScheme.surfaceContainerHighest,
            //         )
            //       : BorderSide.none,
            //   right: isLeft
            //       ? BorderSide.none
            //       : BorderSide(
            //           color: theme.colorScheme.surfaceContainerHighest,
            //         ),
            //   bottom: BorderSide(
            //     color: theme.colorScheme.surfaceContainerHighest,
            //   ),
            //   top: BorderSide(
            //     color: theme.colorScheme.surfaceContainerHighest,
            //   ),
            // ),
            // borderRadius: isLeft
            //     ? const BorderRadius.only(
            //         topLeft: Radius.circular(24),
            //         bottomLeft: Radius.circular(24),
            //       )
            //     : const BorderRadius.only(
            //         topRight: Radius.circular(24),
            //         bottomRight: Radius.circular(24),
            //       ),
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

class _JournalDailyLeftContent extends StatelessWidget {
  const _JournalDailyLeftContent();

  @override
  Widget build(BuildContext context) {
    final date = context.read<JournalDailyBloc>().date;
    final colWidth = ((kDiscoverJournalDailyPageWidth - _spacing * 3) / 2)
        .floorToDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              JournalDailyDateView(date: date),
              const SizedBox(height: _spacing),
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
              const SizedBox(height: _spacing),
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
        const SizedBox(width: _spacing),
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
      width: kDiscoverJournalDailyPageWidth - _spacing * 2,
      height: kDiscoverJournalDailyPageHeight - 32,
      child:
          BlocSelector<JournalDailyBloc, JournalDailyState, List<NoteEntity>>(
            selector: (state) => state.writtenNotes,
            builder: (context, notes) => JournalDailyNoteGridView(
              notes: notes,
              width: kDiscoverJournalDailyPageWidth - _spacing * 2,
            ),
          ),
    );
  }
}
