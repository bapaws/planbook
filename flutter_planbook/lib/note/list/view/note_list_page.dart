import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/note/list/bloc/note_list_bloc.dart';
import 'package:flutter_planbook/note/list/view/note_list_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class NoteListPage extends StatelessWidget {
  const NoteListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NoteListBloc(
        notesRepository: context.read(),
      )..add(NoteListRequested(date: Jiffy.now())),
      child: BlocSelector<NoteListBloc, NoteListState, List<NoteEntity>>(
        selector: (state) => state.notes,
        builder: (context, notes) {
          return NoteListView(notes: notes);
        },
      ),
    );
  }
}
