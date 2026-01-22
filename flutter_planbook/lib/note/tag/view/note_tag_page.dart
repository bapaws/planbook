import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/note/list/view/note_list_view.dart';
import 'package:flutter_planbook/note/tag/bloc/note_tag_bloc.dart';
import 'package:flutter_planbook/root/note/bloc/root_note_bloc.dart';
import 'package:planbook_api/entity/note_entity.dart';

@RoutePage()
class NoteTagPage extends StatelessWidget {
  const NoteTagPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tagId = context.read<RootNoteBloc>().state.tag?.id;
    return BlocProvider(
      create: (context) => NoteTagBloc(
        notesRepository: context.read(),
      )..add(NoteTagRequested(tagId: tagId ?? '')),
      child: BlocListener<RootNoteBloc, RootNoteState>(
        listenWhen: (previous, current) => previous.tag != current.tag,
        listener: (context, state) {
          final tagId = state.tag?.id;
          if (tagId == null) return;
          context.read<NoteTagBloc>().add(NoteTagRequested(tagId: tagId));
        },
        child: const _NoteTagPage(),
      ),
    );
  }
}

class _NoteTagPage extends StatelessWidget {
  const _NoteTagPage();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NoteTagBloc, NoteTagState, List<NoteEntity>>(
      selector: (state) => state.notes,
      builder: (context, notes) {
        return NoteListView(
          notes: notes,
          showDate: true,
          onDeleted: (note) {
            context.read<NoteTagBloc>().add(NoteTagDeleted(note: note));
          },
        );
      },
    );
  }
}
