import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/view/app_tag_view.dart';
import 'package:flutter_planbook/core/model/quadrant_config_x.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_header.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_pie_chart_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';

class JournalMonthlyDataView extends StatelessWidget {
  const JournalMonthlyDataView({
    required this.completedTasksCount,
    required this.plannedTasksCount,
    required this.noteCount,
    required this.wordCount,
    required this.completedByPriority,
    required this.notes,
    super.key,
  });

  final int completedTasksCount;
  final int plannedTasksCount;
  final int noteCount;
  final int wordCount;
  final Map<TaskPriority, int> completedByPriority;
  final List<NoteEntity> notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.outline,
    );

    final numberStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JournalDailyHeader(
          title: context.l10n.monthlyData,
          icon: FaIcon(
            FontAwesomeIcons.trophy,
            size: 14,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          _buildFullRichText(context, baseStyle, numberStyle),
          style: baseStyle,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        if (completedTasksCount > 0) ...[
          Text(
            context.l10n.priorityDistribution,
            style: baseStyle,
          ),
          const SizedBox(height: 12),
          JournalDailyPieChartView(
            taskPriorityCounts: completedByPriority,
          ),
          const SizedBox(height: 12),
        ],
        Text.rich(
          _buildNotesRichText(context, baseStyle, numberStyle),
          style: baseStyle,
          textAlign: TextAlign.start,
        ),
      ],
    );
  }

  TextSpan _buildFullRichText(
    BuildContext context,
    TextStyle? baseStyle,
    TextStyle? numberStyle,
  ) {
    final l10n = context.l10n;
    final spans = <InlineSpan>[];

    if (plannedTasksCount > 0) {
      _addTextWithNumbers(
        spans,
        l10n.monthlyDescriptionPlannedTasks(plannedTasksCount),
        baseStyle,
        numberStyle,
      );
    } else {
      spans.add(
        TextSpan(
          text: l10n.monthlyDescriptionNoPlannedTasks,
          style: baseStyle,
        ),
      );
    }
    spans.add(TextSpan(text: ' ', style: baseStyle));

    if (completedTasksCount == 0) {
      _addTextWithNumbers(
        spans,
        l10n.monthlyDescriptionNoTasks,
        baseStyle,
        numberStyle,
      );
    } else {
      _addTextWithNumbers(
        spans,
        l10n.monthlyDescriptionTasksCompleted(completedTasksCount),
        baseStyle,
        numberStyle,
      );

      final priorityBreakdown = _buildPriorityBreakdown(context);
      if (priorityBreakdown.isNotEmpty) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
        _addTextWithNumbers(
          spans,
          l10n.monthlyDescriptionPriorityBreakdown(priorityBreakdown),
          baseStyle,
          numberStyle,
        );
      }
    }

    final allTags = _collectTags();
    if (allTags.isNotEmpty) {
      spans.add(TextSpan(text: ' ', style: baseStyle));
      _addTagsSection(context, spans, allTags, baseStyle);
    }

    return TextSpan(children: spans);
  }

  TextSpan _buildNotesRichText(
    BuildContext context,
    TextStyle? baseStyle,
    TextStyle? numberStyle,
  ) {
    final l10n = context.l10n;
    final spans = <InlineSpan>[];

    if (noteCount == 0) {
      _addTextWithNumbers(
        spans,
        l10n.monthlyDescriptionNoNotesWritten,
        baseStyle,
        numberStyle,
      );
    } else {
      _addTextWithNumbers(
        spans,
        l10n.monthlyDescriptionNotesWritten(noteCount, wordCount),
        baseStyle,
        numberStyle,
      );
    }

    return TextSpan(children: spans);
  }

  void _addTextWithNumbers(
    List<InlineSpan> spans,
    String text,
    TextStyle? baseStyle,
    TextStyle? numberStyle,
  ) {
    final regex = RegExp(r'\d+\.?\d*');
    var lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: match.group(0),
          style: numberStyle,
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: baseStyle,
        ),
      );
    }
  }

  List<TagEntity> _collectTags() {
    final tagMap = <String, TagEntity>{};

    for (final note in notes) {
      for (final tag in note.tags) {
        tagMap[tag.id] = tag;
      }
    }

    return tagMap.values.take(5).toList();
  }

  void _addTagsSection(
    BuildContext context,
    List<InlineSpan> spans,
    List<TagEntity> tags,
    TextStyle? baseStyle,
  ) {
    final l10n = context.l10n;

    final tagsInvolvedText = l10n.monthlyDescriptionTagsInvolved('');
    final prefix = tagsInvolvedText.replaceAll(RegExp(r'[.。]\s*$'), '');

    spans.add(TextSpan(text: prefix, style: baseStyle));

    for (var i = 0; i < tags.length; i++) {
      final tag = tags[i];

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 4 : 2,
              right: 2,
              top: 2,
              bottom: 2,
            ),
            child: AppTagView(tag: tag),
          ),
        ),
      );
    }

    spans.add(TextSpan(text: l10n.punctuationPeriod, style: baseStyle));
  }

  String _buildPriorityBreakdown(BuildContext context) {
    final l10n = context.l10n;
    final quadrantConfigs = context.read<AppBloc>().state.quadrantConfigs;

    if (completedByPriority.isEmpty) return '';

    final breakdownParts = <String>[];
    final sortedEntries = completedByPriority.entries.toList()
      ..sort((a, b) => a.key.value.compareTo(b.key.value));

    for (final entry in sortedEntries) {
      if (entry.value == 0) continue;

      breakdownParts.add(
        l10n.dailyDescriptionQuadrantCount(
          entry.value,
          quadrantConfigs.nameOf(entry.key, l10n),
        ),
      );
    }

    return breakdownParts.join(l10n.punctuationEnumSeparator);
  }
}
