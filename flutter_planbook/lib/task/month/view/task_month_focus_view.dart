import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/month/bloc/task_month_bloc.dart';
import 'package:planbook_api/planbook_api.dart';

class TaskMonthFocusView extends StatelessWidget {
  const TaskMonthFocusView({required this.note, super.key});

  final Note? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: () {
        final focusAt = context.read<TaskMonthBloc>().state.date;
        context.router.push(
          NoteFocusRoute(
            initialNote: note,
            type: NoteType.monthlyFocus,
            focusAt: focusAt,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
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
                '${context.l10n.monthlyFocus} 🎯',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(
              height: 8,
              width: double.infinity,
            ),
            AnimatedSize(
              duration: Durations.medium1,
              alignment: Alignment.topLeft,
              child: Text(
                note?.content ?? context.l10n.thinkAboutMonthlyFocus,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: note == null
                      ? theme.colorScheme.outlineVariant
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
