import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/tag/bloc/note_tag_bloc.dart';
import 'package:planbook_api/entity/tag_entity.dart';

@RoutePage()
class NoteTagPage extends StatelessWidget {
  const NoteTagPage({required this.tag, super.key});

  final TagEntity tag;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NoteTagBloc(),
      child: const _NoteTagPage(),
    );
  }
}

class _NoteTagPage extends StatelessWidget {
  const _NoteTagPage();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
