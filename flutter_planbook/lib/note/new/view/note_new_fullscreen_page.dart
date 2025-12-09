import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/new/cubit/note_new_cubit.dart';
import 'package:flutter_planbook/note/new/view/note_new_view.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:planbook_repository/planbook_repository.dart' hide Column;

@RoutePage()
class NoteNewFullscreenPage extends StatelessWidget {
  const NoteNewFullscreenPage({this.initialNote, super.key});

  final NoteEntity? initialNote;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NoteNewCubit(
        notesRepository: context.read(),
        assetsRepository: context.read(),
        initialNote: initialNote,
      ),
      child: const _NoteNewFullscreenPage(),
    );
  }
}

class _NoteNewFullscreenPage extends StatelessWidget {
  const _NoteNewFullscreenPage();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: const NavigationBarBackButton(),
        title: Text(
          context.read<NoteNewCubit>().state.initialNote == null
              ? context.l10n.newNote
              : context.l10n.editNote,
        ),
      ),
      body: const NoteNewView(),
    );
  }
}
