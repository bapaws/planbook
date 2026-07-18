import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_focus_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class JournalMonthlyCalendarView extends StatelessWidget {
  const JournalMonthlyCalendarView({
    required this.month,
    this.dailyFocusNotes = const [],
    this.footerNote,
    this.footerNoteType = NoteType.monthlySummary,
    this.headerTitle,
    this.headerColorScheme,
    this.startWeekdayColumn = 0,
    this.endWeekdayColumn = 6,
    this.fillHeight = false,
    super.key,
  });

  final Jiffy month;
  final List<Note?> dailyFocusNotes;
  final Note? footerNote;
  final NoteType footerNoteType;
  final String? headerTitle;
  final ColorScheme? headerColorScheme;
  final int startWeekdayColumn;
  final int endWeekdayColumn;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final startOfMonth = month.startOf(Unit.month);
    final daysInMonth = month.daysInMonth;
    // weekday: 1=Monday, 7=Sunday
    final firstWeekday = startOfMonth.dateTime.weekday;
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells + 6) ~/ 7;
    final columnCount = endWeekdayColumn - startWeekdayColumn + 1;

    Widget dayCell(int day) {
      final note = day <= dailyFocusNotes.length
          ? dailyFocusNotes[day - 1]
          : null;
      final content = note?.content ?? '';
      final hasFocus = content.isNotEmpty;

      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (hasFocus)
              Expanded(
                child: Text(
                  content,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final cells = <Widget>[];
    for (var row = 0; row < rowCount; row++) {
      for (var col = startWeekdayColumn; col <= endWeekdayColumn; col++) {
        final cellIndex = row * 7 + col;
        if (cellIndex < leadingBlanks ||
            cellIndex >= leadingBlanks + daysInMonth) {
          cells.add(const SizedBox.shrink());
        } else {
          final day = cellIndex - leadingBlanks + 1;
          cells.add(dayCell(day));
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget grid;
        if (fillHeight) {
          final headerSpace = headerTitle != null
              ? kJournalDailyHeaderHeight + 12
              : 0.0;
          final availableHeight = (constraints.maxHeight - headerSpace).clamp(
            0.0,
            double.infinity,
          );
          final cellWidth =
              (constraints.maxWidth - (columnCount - 1) * 4) / columnCount;
          final cellHeight = rowCount > 0
              ? (availableHeight - (rowCount - 1) * 4) / rowCount
              : availableHeight;
          final aspectRatio = cellHeight > 0 ? cellWidth / cellHeight : 1.1;

          grid = Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columnCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              children: cells,
            ),
          );
        } else {
          grid = GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columnCount,
            childAspectRatio: 1.1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            children: cells,
          );
        }

        final effectiveHeaderColorScheme = headerColorScheme ?? colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerTitle != null) ...[
              JournalDailyHeader(
                title: headerTitle!,
                icon: Icon(
                  FontAwesomeIcons.arrowsToDot,
                  size: 14,
                  color: effectiveHeaderColorScheme.primary,
                ),
                iconColor: effectiveHeaderColorScheme.onPrimaryContainer,
                iconBackgroundColor:
                    effectiveHeaderColorScheme.primaryContainer,
                badgeColor: effectiveHeaderColorScheme.primaryContainer,
                badgeTextColor: effectiveHeaderColorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 12),
            ],
            grid,
            if (footerNote != null) ...[
              const SizedBox(height: 12),
              Expanded(
                child: JournalDailyFocusView(
                  note: footerNote,
                  noteType: footerNoteType,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
