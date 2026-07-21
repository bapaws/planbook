import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class JournalMonthlyCalendarView extends StatelessWidget {
  const JournalMonthlyCalendarView({
    required this.month,
    this.dailyFocusNotes = const [],
    this.startWeekdayColumn = 0,
    this.endWeekdayColumn = 6,
    this.fillHeight = false,
    super.key,
  });

  final Jiffy month;
  final List<Note?> dailyFocusNotes;

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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
            child: Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
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
        if (fillHeight) {
          final availableHeight =
              constraints.maxHeight.clamp(
                0.0,
                double.infinity,
              ) -
              24;
          final cellWidth =
              (constraints.maxWidth - (columnCount - 1) * 4) / columnCount;
          final cellHeight = rowCount > 0
              ? (availableHeight - (rowCount - 1) * 4) / rowCount
              : availableHeight;
          final aspectRatio = cellHeight > 0 ? cellWidth / cellHeight : 1.1;

          // 高度由 LayoutBuilder 约束 + aspectRatio 决定，
          // 不能再包 Expanded（父级不是 Flex）。
          return GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columnCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: cells,
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columnCount,
          childAspectRatio: 1.1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: cells,
        );
      },
    );
  }
}
