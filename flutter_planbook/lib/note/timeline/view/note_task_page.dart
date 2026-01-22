import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/note/timeline/view/note_timeline_page.dart';
import 'package:planbook_api/entity/note_entity.dart';

@RoutePage()
class NoteTaskPage extends StatelessWidget {
  const NoteTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NoteTimelinePage(
      key: ValueKey('task'),
      mode: NoteListMode.task,
    );
  }
}
