import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/view/app_tag_view.dart';
import 'package:flutter_planbook/discover/daily/bloc/journal_daily_bloc.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_header.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_pie_chart_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';

class JournalDailyDataView extends StatelessWidget {
  const JournalDailyDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalDailyBloc, JournalDailyState>(
      builder: (context, state) {
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
              title: context.l10n.dailyData,
              icon: Icon(
                FontAwesomeIcons.trophy,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              _buildFullRichText(context, state, baseStyle, numberStyle),
              style: baseStyle,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 8),
            if (state.completedTasksCount > 0) ...[
              Text(
                context.l10n.priorityDistribution,
                style: baseStyle,
              ),
              const SizedBox(height: 12),
              JournalDailyPieChartView(
                taskPriorityCounts: state.completedTaskPriorityCounts,
              ),
              const SizedBox(height: 12),
            ],
            Text.rich(
              _buildNotesRichText(context, state, baseStyle, numberStyle),
              style: baseStyle,
              textAlign: TextAlign.start,
            ),
          ],
        );
      },
    );
  }

  /// 构建完整的富文本，包含文字描述和标签
  TextSpan _buildFullRichText(
    BuildContext context,
    JournalDailyState state,
    TextStyle? baseStyle,
    TextStyle? numberStyle,
  ) {
    final l10n = context.l10n;
    final spans = <InlineSpan>[];

    // 计划任务统计
    final plannedCount = state.plannedTasksCount;
    if (plannedCount > 0) {
      _addTextWithNumbers(
        spans,
        l10n.dailyDescriptionPlannedTasks(plannedCount),
        baseStyle,
        numberStyle,
      );
    } else {
      spans.add(
        TextSpan(text: l10n.dailyDescriptionNoPlannedTasks, style: baseStyle),
      );
    }
    spans.add(TextSpan(text: ' ', style: baseStyle));

    // 完成任务统计
    final completedFromPlan = state.completedTasksCount;
    final completedFromInbox = state.completedInboxTasksCount;
    final totalCompleted = completedFromPlan + completedFromInbox;

    if (totalCompleted == 0) {
      _addTextWithNumbers(
        spans,
        l10n.dailyDescriptionNoTasks,
        baseStyle,
        numberStyle,
      );
    } else {
      // 完成了 X 项任务
      _addTextWithNumbers(
        spans,
        l10n.dailyDescriptionTasksCompleted(totalCompleted),
        baseStyle,
        numberStyle,
      );

      // 区分计划和收集箱中的任务
      if (completedFromPlan > 0 || completedFromInbox > 0) {
        final breakdownParts = <String>[];
        if (completedFromPlan > 0) {
          breakdownParts.add(
            l10n.dailyDescriptionCompletedFromPlan(completedFromPlan),
          );
        }
        if (completedFromInbox > 0) {
          breakdownParts.add(
            l10n.dailyDescriptionCompletedFromInbox(completedFromInbox),
          );
        }
        spans.add(TextSpan(text: l10n.punctuationOpenParen, style: baseStyle));
        _addTextWithNumbers(
          spans,
          breakdownParts.join(l10n.punctuationListSeparator),
          baseStyle,
          numberStyle,
        );
        spans.add(TextSpan(text: l10n.punctuationCloseParen, style: baseStyle));
      }

      // 优先级分布
      final priorityBreakdown = _buildPriorityBreakdown(context, state);
      if (priorityBreakdown.isNotEmpty) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
        _addTextWithNumbers(
          spans,
          l10n.dailyDescriptionPriorityBreakdown(priorityBreakdown),
          baseStyle,
          numberStyle,
        );
      }
    }

    // 标签统计
    final allTags = _collectTags(state);
    if (allTags.isNotEmpty) {
      spans.add(TextSpan(text: ' ', style: baseStyle));
      _addTagsSection(context, spans, allTags, baseStyle);
    }

    return TextSpan(children: spans);
  }

  TextSpan _buildNotesRichText(
    BuildContext context,
    JournalDailyState state,
    TextStyle? baseStyle,
    TextStyle? numberStyle,
  ) {
    final l10n = context.l10n;
    final spans = <InlineSpan>[];

    // 日记统计
    final notes = state.writtenNotes;
    final noteCount = notes.length;

    if (noteCount == 0) {
      _addTextWithNumbers(
        spans,
        l10n.dailyDescriptionNoNotesWritten,
        baseStyle,
        numberStyle,
      );
    } else {
      // 计算总字数
      var totalWords = 0;
      for (final note in notes) {
        final content = note.content ?? '';
        final title = note.title;
        totalWords += _countWords(content) + _countWords(title);
      }
      _addTextWithNumbers(
        spans,
        l10n.dailyDescriptionNotesWritten(noteCount, totalWords),
        baseStyle,
        numberStyle,
      );
    }
    return TextSpan(children: spans);
  }

  /// 添加带数字高亮的文本
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

  /// 收集所有标签实体
  List<TagEntity> _collectTags(JournalDailyState state) {
    final tagMap = <String, TagEntity>{};

    // 从任务中获取标签
    for (final task in state.tasks) {
      for (final tag in task.tags) {
        tagMap[tag.id] = tag;
      }
    }

    // 从日记中获取标签
    for (final note in state.writtenNotes) {
      for (final tag in note.tags) {
        tagMap[tag.id] = tag;
      }
    }

    // 限制最多显示 5 个标签
    return tagMap.values.take(5).toList();
  }

  /// 添加标签部分
  void _addTagsSection(
    BuildContext context,
    List<InlineSpan> spans,
    List<TagEntity> tags,
    TextStyle? baseStyle,
  ) {
    final l10n = context.l10n;

    // 添加 "涉及标签：" 前缀
    // 需要分割多语言字符串，提取前缀部分
    final tagsInvolvedText = l10n.dailyDescriptionTagsInvolved('');
    // 移除末尾的句号和空格
    final prefix = tagsInvolvedText.replaceAll(RegExp(r'[.。]\s*$'), '');

    spans.add(TextSpan(text: prefix, style: baseStyle));

    // 添加标签 widgets
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

    // 添加句号
    spans.add(TextSpan(text: l10n.punctuationPeriod, style: baseStyle));
  }

  String _buildPriorityBreakdown(
    BuildContext context,
    JournalDailyState state,
  ) {
    final l10n = context.l10n;
    final priorityCounts = state.taskPriorityCounts;

    if (priorityCounts.isEmpty) return '';

    final breakdownParts = <String>[];

    // 按优先级从高到低排序
    final sortedCounts = List<JournalDailyTaskPriorityCount>.from(
      priorityCounts,
    )..sort((a, b) => a.priority.value.compareTo(b.priority.value));

    for (final count in sortedCounts) {
      if (count.totalCount == 0) continue;

      final text = switch (count.priority) {
        TaskPriority.high => l10n.dailyDescriptionImportantUrgentCount(
          count.totalCount,
        ),
        TaskPriority.medium => l10n.dailyDescriptionImportantNotUrgentCount(
          count.totalCount,
        ),
        TaskPriority.low => l10n.dailyDescriptionUrgentNotImportantCount(
          count.totalCount,
        ),
        TaskPriority.none => l10n.dailyDescriptionNotUrgentNotImportantCount(
          count.totalCount,
        ),
      };
      breakdownParts.add(text);
    }

    return breakdownParts.join(l10n.punctuationEnumSeparator);
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.replaceAll(RegExp(r'\s+'), '').length;
  }
}
