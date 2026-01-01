import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/focus/model/note_type_x.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/database/note_type.dart';

class TaskFocusView extends StatelessWidget {
  const TaskFocusView({
    required this.note,
    required this.type,
    required this.onTap,
    super.key,
  });

  final Note? note;
  final NoteType type;
  final VoidCallback onTap;

  RootTaskTab get tab => switch (type) {
    NoteType.dailyFocus => RootTaskTab.day,
    NoteType.weeklyFocus => RootTaskTab.week,
    NoteType.monthlyFocus => RootTaskTab.month,
    _ => throw UnimplementedError(),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocSelector<RootTaskBloc, RootTaskState, NoteType?>(
      selector: (state) => state.tabFocusNoteTypes[tab],
      builder: (context, noteType) => AnimatedSwitcher(
        duration: Durations.medium1,
        transitionBuilder: (child, animation) => SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
        child: noteType == null
            ? null
            : GestureDetector(
                onTap: onTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.surfaceContainer,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primaryContainer,
                              ),
                            ),
                            child: Text(
                              '${type.getTitle(context.l10n)} 🎯',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const Spacer(),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            sizeStyle: CupertinoButtonSize.small,
                            minimumSize: const Size.square(21),
                            onPressed: () {
                              context.read<RootTaskBloc>().add(
                                RootTaskTabFocusNoteTypeChanged(
                                  tab: tab,
                                ),
                              );
                            },
                            child: Icon(
                              FontAwesomeIcons.xmark,
                              size: 14,
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                        width: double.infinity,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AnimatedSize(
                          duration: Durations.medium1,
                          alignment: Alignment.topLeft,
                          child: Text(
                            note?.content ?? type.getHintText(context.l10n),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: note == null
                                  ? theme.colorScheme.outlineVariant
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
