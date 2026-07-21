import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/discover/monthly/view/journal_monthly_calendar_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/database/note_type.dart';

/// 月重点左页右侧的“周重点”列。
///
/// 每行对应当前月份月历中的一周，显示周数与周重点内容；点击可编辑。
/// 行高通过 [LayoutBuilder] 按与 [JournalMonthlyCalendarView] 相同的
/// rowCount / spacing 计算，保证与相邻日历行对齐。
class JournalMonthlyWeekColumn extends StatelessWidget {
  const JournalMonthlyWeekColumn({
    required this.month,
    required this.weeklyFocusNotes,

    super.key,
  });

  final Jiffy month;
  final List<Note?> weeklyFocusNotes;

  @override
  Widget build(BuildContext context) {
    final startOfMonth = month.startOf(Unit.month);
    final daysInMonth = startOfMonth.daysInMonth;
    final firstWeekday = startOfMonth.dateTime.weekday;
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells + 6) ~/ 7;
    final firstMonday = startOfMonth.subtract(
      days: startOfMonth.dateTime.weekday - 1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight =
            constraints.maxHeight.clamp(
              0.0,
              double.infinity,
            ) -
            24;
        final rowHeight = rowCount > 0
            ? (availableHeight - (rowCount - 1) * 4) / rowCount
            : availableHeight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            for (var row = 0; row < rowCount; row++) ...[
              if (row > 0) const SizedBox(height: 4),
              SizedBox(
                width: constraints.maxWidth,
                height: rowHeight,
                child: _WeekFocusCell(
                  weekStart: firstMonday.add(weeks: row),
                  note: row < weeklyFocusNotes.length
                      ? weeklyFocusNotes[row]
                      : null,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _WeekFocusCell extends StatelessWidget {
  const _WeekFocusCell({
    required this.weekStart,
    required this.note,
  });

  final Jiffy weekStart;
  final Note? note;

  void _edit(BuildContext context) {
    context.router.push(
      NoteNewTypeRoute(
        type: NoteType.weeklyFocus,
        focusAt: weekStart,
        initialNote: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.colorSchemeForMonth(weekStart.month);
    final l10n = context.l10n;
    final content = note?.content ?? '';
    final hasFocus = content.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _edit(context),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.weekOfYear(weekStart.weekOfYear),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                hasFocus ? content : NoteType.weeklyFocus.getHintText(l10n),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: hasFocus
                      ? colorScheme.onPrimaryContainer
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
