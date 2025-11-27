import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/note/new/cubit/note_new_cubit.dart';
import 'package:flutter_planbook/note/new/view/note_new_view.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class NoteNewPage extends StatelessWidget {
  const NoteNewPage({this.initialNote, this.initialTask, super.key});

  final NoteEntity? initialNote;
  final TaskEntity? initialTask;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => NoteNewCubit(
        notesRepository: context.read(),
        initialNote: initialNote,
        initialTask: initialTask,
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
            image: const DecorationImage(
              image: AssetImage('assets/images/bg_tile.png'),
              repeat: ImageRepeat.repeat,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.hardEdge,
          child: const NoteNewView(),
        ),
      ),
    );
  }
}
