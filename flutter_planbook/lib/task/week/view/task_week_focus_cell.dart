import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/today/view/task_focus_header_view.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/database/note_type.dart';

class TaskWeekFocusCell extends StatelessWidget {
  const TaskWeekFocusCell({
    required this.note,
    required this.noteType,
    super.key,
  });

  final Note? note;
  final NoteType noteType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: GestureDetector(
          onTap: () {
            context.router.push(
              NoteNewTypeRoute(
                initialNote: note,
                type: noteType,
                focusAt: note?.focusAt ?? Jiffy.now(),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              TaskFocusHeaderView(
                noteType: noteType,
                tab: RootTaskTab.week,
                onMindMapTapped: () {
                  _addDiscoverEvent(context, noteType);
                  _navigateToRootDiscover(context, noteType);
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      note?.content ?? noteType.getHintText(context.l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: note == null
                            ? theme.colorScheme.outlineVariant
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addDiscoverEvent(BuildContext context, NoteType noteType) {
    final date = context.read<TaskWeekBloc>().state.date;
    context.read<RootDiscoverBloc>().add(
      noteType.isFocus
          ? RootDiscoverFocusDateChanged(
              date: date,
              type: noteType,
            )
          : RootDiscoverSummaryDateChanged(
              date: date,
              type: noteType,
            ),
    );
  }

  void _navigateToRootDiscover(BuildContext context, NoteType noteType) {
    AutoRouter.of(context).navigate(
      RootHomeRoute(
        children: [
          RootDiscoverRoute(
            children: [
              if (noteType.isFocus)
                const DiscoverFocusRoute()
              else
                const DiscoverSummaryRoute(),
            ],
          ),
        ],
      ),
    );
  }
}
