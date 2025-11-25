import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/note/new/cubit/note_new_cubit.dart';
import 'package:flutter_planbook/note/new/view/note_new_view.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart' hide Column;

@RoutePage()
class NoteNewPage extends StatelessWidget {
  const NoteNewPage({this.initialNote, super.key});

  final NoteEntity? initialNote;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NoteNewCubit(
        notesRepository: context.read(),
        initialNote: initialNote,
      ),
      child: BlocListener<NoteNewCubit, NoteNewState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == PageStatus.success,
        listener: (context, state) {
          context.router.maybePop();
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.vertical -
                64,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.hardEdge,
          child: const AppPageScaffold(child: NoteNewView()),
        ),
      ),
    );
  }
}
