import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_calendar_view.dart';
import 'package:flutter_planbook/core/view/app_empty_note_view.dart';
import 'package:flutter_planbook/note/list/bloc/note_list_bloc.dart';
import 'package:flutter_planbook/note/list/view/note_list_view.dart';
import 'package:flutter_planbook/note/timeline/bloc/note_timeline_bloc.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class NoteTimelinePage extends StatelessWidget {
  const NoteTimelinePage({super.key, this.mode = NoteListMode.all});

  final NoteListMode mode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final date = context.read<NoteTimelineBloc>().state.date;
            final bloc = NoteListBloc(
              notesRepository: context.read(),
            )..add(NoteListRequested(date: date, mode: mode));
            return bloc;
          },
        ),
      ],
      child: BlocListener<NoteTimelineBloc, NoteTimelineState>(
        listenWhen: (previous, current) => previous.date != current.date,
        listener: (context, state) {
          context.read<NoteListBloc>().add(
            NoteListRequested(date: state.date, mode: mode),
          );
        },
        child: const _NoteTimelinePage(),
      ),
    );
  }
}

class _NoteTimelinePage extends StatelessWidget {
  const _NoteTimelinePage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteTimelineBloc, NoteTimelineState>(
      builder: (context, state) {
        return Column(
          children: [
            AppCalendarView<void>(
              date: state.date,
              calendarFormat: state.calendarFormat,
              onDateSelected: (date) {
                context.read<NoteTimelineBloc>().add(
                  NoteTimelineDateSelected(date: date),
                );
              },
            ),
            Expanded(
              child:
                  BlocSelector<NoteListBloc, NoteListState, List<NoteEntity>>(
                    selector: (state) => state.notes,
                    builder: (context, notes) {
                      if (notes.isEmpty) {
                        return const AppEmptyNoteView();
                      }
                      final key = ValueKey(state.date.dateKey);
                      return AnimatedSwitcher(
                        duration: Durations.medium1,
                        child: NoteListView(
                          key: key,
                          notes: notes,
                          onDeleted: (note) {
                            context.read<NoteListBloc>().add(
                              NoteListDeleted(note: note),
                            );
                          },
                        ),
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }
}
