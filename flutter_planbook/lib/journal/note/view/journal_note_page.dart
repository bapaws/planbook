import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/journal/note/bloc/journal_note_bloc.dart';
import 'package:flutter_planbook/journal/note/view/journal_note_list_view.dart';
import 'package:jiffy/jiffy.dart';

@RoutePage()
class JournalNotePage extends StatelessWidget {
  const JournalNotePage({required this.date, super.key});

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalNoteBloc, JournalNoteState>(
      builder: (context, state) {
        return JournalNoteListView(notes: state.notes);
      },
    );
  }
}
