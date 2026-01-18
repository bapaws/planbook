import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/core/view/app_empty_note_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_header.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_note_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_pinned_layout.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:planbook_api/entity/note_entity.dart';

/// 手账笔记瀑布流视图
class JournalDailyNoteGridView extends StatelessWidget {
  const JournalDailyNoteGridView({
    required this.notes,
    required this.width,
    this.crossAxisCount = 2,
    this.onNoteTap,
    super.key,
  });

  final List<NoteEntity> notes;
  final int crossAxisCount;
  final void Function(NoteEntity note)? onNoteTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const AppEmptyNoteView(top: kDiscoverJournalDailyPageHeight / 5);
    }

    // 1~4 篇时使用"贴在页面"定制布局
    if (notes.length <= 4) {
      return JournalDailyPinnedLayout(
        notes: notes,
        width: width,
        onNoteTap: onNoteTap,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 手账标题区域
        JournalDailyHeader(
          title: context.l10n.notes,
          count: notes.length,
          icon: Icon(
            Icons.auto_awesome,
            size: 16,
            color: context.pinkColorScheme.primary,
          ),
          iconColor: context.pinkColorScheme.primary,
          iconBackgroundColor: context.pinkColorScheme.primaryContainer,
          badgeColor: context.pinkColorScheme.secondaryContainer,
          badgeTextColor: context.pinkColorScheme.onSecondaryContainer,
        ),
        const SizedBox(height: 12),
        // 瀑布流笔记
        Expanded(
          child: MasonryGridView.count(
            clipBehavior: Clip.none,
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final style = _getCardStyle(index);
              final tapeStyle = _getTapeStyle(note, index);
              final rotation = _getRotation(index);
              return Transform.rotate(
                angle: rotation,
                child: JournalDailyNoteView(
                  note: note,
                  width: ((width - 10) / crossAxisCount).floorToDouble(),
                  style: style,
                  tapeStyle: tapeStyle,
                  onTap: () => onNoteTap?.call(note),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 根据索引获取卡片风格
  NoteCardStyle _getCardStyle(int index) {
    const styles = [
      NoteCardStyle.polaroid,
      // NoteCardStyle.glass,
      // NoteCardStyle.pastel,
      NoteCardStyle.polaroid,
      // NoteCardStyle.outline,
      NoteCardStyle.strip,
    ];
    return styles[index % styles.length];
  }

  /// 根据笔记和索引获取胶带风格（可为空）
  TapeStyle? _getTapeStyle(NoteEntity note, int index) {
    // 通过 hash 保持稳定性，同时制造一定随机性
    final seed = note.id.hashCode ^ index;
    final random = math.Random(seed);
    final roll = random.nextDouble();

    // 40% 不加胶带
    if (roll < 0.4) return null;

    const tapes = [
      TapeStyle.stripe,
      TapeStyle.dots,
      TapeStyle.grid,
      TapeStyle.gradient,
      TapeStyle.washi,
    ];
    return tapes[seed % tapes.length];
  }

  /// 获取轻微旋转角度
  double _getRotation(int index) {
    // 使用固定种子确保一致性
    final random = math.Random(index * 42);
    // 生成 -1.5 到 1.5 度之间的旋转
    return (random.nextDouble() - 0.5) * 0.05;
  }
}
