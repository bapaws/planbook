import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/discover/daily/bloc/journal_daily_bloc.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_data_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_date_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_focus_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_note_grid_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_timeline_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

const double kDiscoverJournalDailyPageWidth = 210 * 2 * 2.5;
const double kDiscoverJournalDailyPageHeight = 297 * 2.5;

@RoutePage()
class JournalDailyPage extends StatelessWidget {
  const JournalDailyPage({required this.date, super.key});

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JournalDailyBloc(
        date: date,
        notesRepository: context.read(),
        tasksRepository: context.read(),
      )..add(const JournalDailyRequested()),
      child: const _JournalDailyPage(),
    );
  }
}

class _JournalDailyPage extends StatelessWidget {
  const _JournalDailyPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = context.read<JournalDailyBloc>().date;
    const spacing = 16.0;
    const pageWidth = kDiscoverJournalDailyPageWidth / 2;
    return BlocSelector<AppBloc, AppState, AppBackgroundEntity?>(
      selector: (state) => state.background,
      builder: (context, background) {
        return Container(
          width: kDiscoverJournalDailyPageWidth,
          height: kDiscoverJournalDailyPageHeight,
          padding: const EdgeInsets.all(spacing),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
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
          child: Row(
            children: [
              SizedBox(
                width: ((pageWidth - spacing * 3) / 2).floorToDouble(),
                child: Column(
                  children: [
                    JournalDailyDateView(date: date),
                    const SizedBox(height: spacing),
                    const JournalDailyDataView(),
                    // const SizedBox(height: spacing * 2),
                    const Spacer(),
                    Flexible(
                      child:
                          BlocSelector<
                            JournalDailyBloc,
                            JournalDailyState,
                            Note?
                          >(
                            selector: (state) => state.focusNote,
                            builder: (context, focusNote) =>
                                JournalDailyFocusView(
                                  note: focusNote,
                                  noteType: NoteType.dailyFocus,
                                  colorScheme: context.yellowColorScheme,
                                ),
                          ),
                    ),
                    const SizedBox(height: spacing),
                    Flexible(
                      child:
                          BlocSelector<
                            JournalDailyBloc,
                            JournalDailyState,
                            Note?
                          >(
                            selector: (state) => state.summaryNote,
                            builder: (context, focusNote) =>
                                JournalDailyFocusView(
                                  note: focusNote,
                                  noteType: NoteType.dailySummary,
                                  colorScheme: context.blueColorScheme,
                                ),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: ((pageWidth - spacing * 3) / 2).floorToDouble(),
                height: kDiscoverJournalDailyPageHeight - 32,
                child: const JournalDailyTimelineView(),
              ),
              const SizedBox(width: spacing * 2 - 2),
              SizedBox(
                width: pageWidth - spacing * 2,
                height: kDiscoverJournalDailyPageHeight - 32,
                child:
                    BlocSelector<
                      JournalDailyBloc,
                      JournalDailyState,
                      List<NoteEntity>
                    >(
                      selector: (state) => state.writtenNotes,
                      builder: (context, notes) => JournalDailyNoteGridView(
                        notes: notes,
                        width: pageWidth - spacing * 2,
                      ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
