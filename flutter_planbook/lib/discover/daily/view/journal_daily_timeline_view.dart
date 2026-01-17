import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/discover/daily/bloc/journal_daily_bloc.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_header.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/entity/note_entity.dart';

const double kJournalDailyTimelineTimeWidth = 44;

class JournalDailyTimelineView extends StatelessWidget {
  const JournalDailyTimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalDailyBloc, JournalDailyState>(
      builder: (context, state) {
        final morningColorScheme = context.indigoColorScheme;
        final afternoonColorScheme = context.orangeColorScheme;
        final eveningColorScheme = context.limeColorScheme;
        return ListView(
          children: [
            JournalDailyHeader(
              title: context.l10n.morning,
              icon: Icon(
                CupertinoIcons.sun_min_fill,
                size: 16,
                color: morningColorScheme.primary,
              ),
              count: state.morningTaskNotes.length,
              iconColor: morningColorScheme.primary,
              iconBackgroundColor: morningColorScheme.primaryContainer,
              badgeColor: morningColorScheme.secondaryContainer,
              badgeTextColor: morningColorScheme.onSecondaryContainer,
            ),
            const SizedBox(height: 12),
            for (final note in state.morningTaskNotes)
              _buildNoteListTile(context, note),
            const SizedBox(height: 12),
            JournalDailyHeader(
              title: context.l10n.afternoon,
              icon: Icon(
                CupertinoIcons.sun_max_fill,
                size: 16,
                color: afternoonColorScheme.primary,
              ),
              count: state.afternoonTaskNotes.length,
              iconColor: afternoonColorScheme.primary,
              iconBackgroundColor: afternoonColorScheme.primaryContainer,
              badgeColor: afternoonColorScheme.secondaryContainer,
              badgeTextColor: afternoonColorScheme.onSecondaryContainer,
            ),
            const SizedBox(height: 12),
            for (final note in state.afternoonTaskNotes)
              _buildNoteListTile(context, note),
            const SizedBox(height: 12),
            JournalDailyHeader(
              title: context.l10n.evening,
              icon: Icon(
                CupertinoIcons.moon_stars_fill,
                size: 16,
                color: eveningColorScheme.primary,
              ),
              count: state.eveningTaskNotes.length,
              iconColor: eveningColorScheme.primary,
              iconBackgroundColor: eveningColorScheme.primaryContainer,
              badgeColor: eveningColorScheme.secondaryContainer,
              badgeTextColor: eveningColorScheme.onSecondaryContainer,
            ),
            const SizedBox(height: 12),
            for (final note in state.eveningTaskNotes)
              _buildNoteListTile(context, note),
          ],
        );
      },
    );
  }

  Widget _buildNoteListTile(BuildContext context, NoteEntity note) {
    final theme = Theme.of(context);
    final createdAt = note.createdAt;
    final colorScheme =
        note.task?.priority?.getColorScheme(context) ??
        Theme.of(context).colorScheme;
    final hasImages = note.images.isNotEmpty;

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.primaryContainer,
                ),
              ),
              child: Text(
                createdAt.jm,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 6, height: 36),
            Expanded(
              child: Text(
                note.task?.title ?? note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        if ((note.content != null && note.content!.isNotEmpty) ||
            hasImages) ...[
          IntrinsicHeight(
            child: Row(
              children: [
                VerticalDivider(
                  thickness: 1,
                  width: kJournalDailyTimelineTimeWidth,
                  color: colorScheme.surfaceContainerHighest,
                ),
                Expanded(
                  child: Column(
                    spacing: 6,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.content != null && note.content!.isNotEmpty)
                        Text(
                          note.content!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      if (hasImages) ...[
                        _TimelineNoteImages(
                          images: note.images,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

/// 时间线笔记图片展示组件
class _TimelineNoteImages extends StatelessWidget {
  const _TimelineNoteImages({
    required this.images,
    required this.colorScheme,
  });

  final List<String> images;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final display = images.take(9).toList();
    final more = images.length - display.length;

    // 单张图片：显示固定高度的大图
    // if (display.length == 1) {
    //   return ClipRRect(
    //     borderRadius: BorderRadius.circular(8),
    //     child: SizedBox(
    //       height: 120,
    //       width: double.infinity,
    //       child: AppNetworkImage(
    //         url: display[0],
    //         width: double.infinity,
    //         height: 120,
    //       ),
    //     ),
    //   );
    // }

    // 多张图片：统一使用方形九宫格布局

    return _buildGridLayout(display, more);
  }

  Widget _buildGridLayout(List<String> display, int more) {
    const spacing = 4.0;
    final tileSize =
        (((kDiscoverJournalDailyPageWidth / 2 - 16 * 3) / 2 -
                    kJournalDailyTimelineTimeWidth -
                    spacing * 2) /
                3)
            .floorToDouble();
    final count = display.length;

    // 统一使用每行最多 3 张的九宫格布局
    final rows = <Widget>[];
    final rowCount = (count / 3).ceil();

    for (var i = 0; i < rowCount; i++) {
      final start = i * 3;
      var end = (i + 1) * 3;
      if (end > count) end = count;

      rows.add(
        _buildRow(
          display.sublist(start, end),
          tileSize,
          spacing,
          // 只有最后一行最后一张图才显示 +N
          more: (i == rowCount - 1) ? more : 0,
        ),
      );
      if (i < rowCount - 1) {
        rows.add(const SizedBox(height: spacing));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  /// 构建单行图片
  Widget _buildRow(
    List<String> rowImages,
    double size,
    double spacing, {
    int more = 0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rowImages.length; i++) ...[
          SizedBox(
            width: size,
            height: size,
            child: (i == rowImages.length - 1 && more > 0)
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _tile(rowImages[i], size, size),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$more',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : _tile(rowImages[i], size, size),
          ),
          if (i < rowImages.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }

  Widget _tile(String url, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: AppNetworkImage(
        url: url,
        width: width,
        height: height,
      ),
    );
  }
}
