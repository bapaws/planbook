import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_header.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_note_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/entity/note_entity.dart';

/// 小数量（1~4）的定制贴纸布局
class JournalDailyPinnedLayout extends StatelessWidget {
  const JournalDailyPinnedLayout({
    required this.notes,
    required this.width,
    this.onNoteTap,
    super.key,
  });

  final List<NoteEntity> notes;
  final void Function(NoteEntity note)? onNoteTap;
  final double width;

  List<NoteCardStyle> get styles => [
    NoteCardStyle.polaroid,
    NoteCardStyle.strip,
    NoteCardStyle.polaroid,
    NoteCardStyle.strip,
  ];
  List<TapeStyle?> get tapeStyles => [
    TapeStyle.stripe,
    TapeStyle.dots,
    TapeStyle.washi,
    null,
    TapeStyle.gradient,
  ];

  List<double> get rotations => [-0.03, 0.025, -0.015, 0.02];

  @override
  Widget build(BuildContext context) {
    assert(notes.isNotEmpty && notes.length <= 4, '仅支持 1~4 张笔记');

    final pinkColorScheme = context.pinkColorScheme;
    return Column(
      children: [
        JournalDailyHeader(
          title: context.l10n.notes,
          count: notes.length,
          icon: Icon(
            Icons.auto_awesome,
            size: 16,
            color: pinkColorScheme.primary,
          ),
          iconColor: pinkColorScheme.primary,
          iconBackgroundColor: pinkColorScheme.primaryContainer,
          badgeColor: pinkColorScheme.secondaryContainer,
          badgeTextColor: pinkColorScheme.onSecondaryContainer,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildLayout(notes),
        ),
      ],
    );
  }

  Widget _buildLayout(
    List<NoteEntity> notes,
  ) {
    // 1 张：居中展示
    if (notes.length == 1) {
      return _buildSingleLayout(notes[0]);
    }

    return _buildTwoLayout(notes);
    // 2 张：错开对角线排列
    if (notes.length == 2) {
      return _buildTwoLayout(notes);
    }

    // 3 张：三角形错落排列
    if (notes.length == 3) {
      return _buildThreeLayout(notes);
    }

    // 4 张：四角错落排列
    return _buildFourLayout(notes);
  }

  /// 单张笔记布局
  Widget _buildSingleLayout(NoteEntity note) {
    final hashCode = note.id.hashCode;
    return Center(
      child: Transform.rotate(
        angle: rotations[hashCode % rotations.length],
        child: JournalDailyNoteView(
          note: note,
          style: styles[hashCode % styles.length],
          tapeStyle: tapeStyles[hashCode % tapeStyles.length],
          width: (width * 0.65).floorToDouble(),
          onTap: () => onNoteTap?.call(note),
        ),
      ),
    );
  }

  /// 两张笔记布局（对角线）
  Widget _buildTwoLayout(List<NoteEntity> notes) {
    return Stack(
      children: [
        // 第二张：右下，向右旋转
        Positioned(
          right: 0,
          bottom: 16,
          child: Transform.rotate(
            angle: rotations[notes[1].id.hashCode % rotations.length],
            child: JournalDailyNoteView(
              note: notes[1],
              style: styles[notes[1].id.hashCode % styles.length],
              tapeStyle: tapeStyles[notes[1].id.hashCode % tapeStyles.length],
              width: (width * 0.55).floorToDouble(),
              onTap: () => onNoteTap?.call(notes[1]),
            ),
          ),
        ),
        // 第一张：左上，向左旋转
        Positioned(
          left: 0,
          top: 16,
          child: Transform.rotate(
            angle: rotations[notes[0].id.hashCode % rotations.length],
            child: JournalDailyNoteView(
              note: notes[0],
              style: styles[notes[0].id.hashCode % styles.length],
              tapeStyle: tapeStyles[notes[0].id.hashCode % tapeStyles.length],
              width: (width * 0.55).floorToDouble(),
              onTap: () => onNoteTap?.call(notes[0]),
            ),
          ),
        ),
      ],
    );
  }

  /// 三张笔记布局（三角形）
  Widget _buildThreeLayout(List<NoteEntity> notes) {
    return Stack(
      children: [
        // 第三张：底部居中偏左
        Positioned(
          left: 0,
          bottom: 16,
          child: Transform.rotate(
            angle: rotations[notes[2].id.hashCode % rotations.length],
            child: JournalDailyNoteView(
              note: notes[2],
              style: styles[notes[2].id.hashCode % styles.length],
              tapeStyle: tapeStyles[notes[2].id.hashCode % tapeStyles.length],
              width: (width * 0.55).floorToDouble(),
              onTap: () => onNoteTap?.call(notes[2]),
            ),
          ),
        ),
        // 第二张：右上偏下
        Positioned(
          right: 0,
          top: 16,
          child: Transform.rotate(
            angle: rotations[notes[1].id.hashCode % rotations.length],
            child: JournalDailyNoteView(
              note: notes[1],
              style: styles[notes[1].id.hashCode % styles.length],
              tapeStyle: tapeStyles[notes[1].id.hashCode % tapeStyles.length],
              width: (width * 0.55).floorToDouble(),
              onTap: () => onNoteTap?.call(notes[1]),
            ),
          ),
        ),
        // 第一张：左上
        Positioned(
          left: 0,
          top: 16,
          child: Transform.rotate(
            angle: rotations[notes[0].id.hashCode % rotations.length],
            child: JournalDailyNoteView(
              note: notes[0],
              style: styles[notes[0].id.hashCode % styles.length],
              tapeStyle: tapeStyles[notes[0].id.hashCode % tapeStyles.length],
              width: (width * 0.55).floorToDouble(),
              onTap: () => onNoteTap?.call(notes[0]),
            ),
          ),
        ),
      ],
    );
  }

  /// 四张笔记布局（四角）
  Widget _buildFourLayout(List<NoteEntity> notes) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 第三张：左下
        Positioned(
          left: 0,
          bottom: 16,
          child: Transform.rotate(
            angle: rotations[notes[2].id.hashCode % rotations.length],
            child: JournalDailyNoteView(
              note: notes[2],
              style: styles[notes[2].id.hashCode % styles.length],
              tapeStyle: tapeStyles[notes[2].id.hashCode % tapeStyles.length],
              width: (width * 0.55).floorToDouble(),
              onTap: () => onNoteTap?.call(notes[2]),
            ),
          ),
        ),
        // 第四张：右下
        Positioned(
          right: 16,
          bottom: 8,
          child: Transform.rotate(
            angle: rotations[notes[3].id.hashCode % rotations.length],
            child: JournalDailyNoteView(
              note: notes[3],
              style: styles[notes[3].id.hashCode % styles.length],
              tapeStyle: tapeStyles[notes[3].id.hashCode % tapeStyles.length],
              width: (width * 0.55).floorToDouble(),
              onTap: () => onNoteTap?.call(notes[3]),
            ),
          ),
        ),
        // 第二张：右上
        Positioned(
          right: 8,
          top: 16,
          child: Transform.rotate(
            angle: rotations[notes[1].id.hashCode % rotations.length],
            child: JournalDailyNoteView(
              note: notes[1],
              style: styles[notes[1].id.hashCode % styles.length],
              tapeStyle: tapeStyles[notes[1].id.hashCode % tapeStyles.length],
              width: (width * 0.55).floorToDouble(),
              onTap: () => onNoteTap?.call(notes[1]),
            ),
          ),
        ),
        // 第一张：左上
        Positioned(
          left: 0,
          top: 8,
          child: Transform.rotate(
            angle: rotations[notes[0].id.hashCode % rotations.length],
            child: JournalDailyNoteView(
              note: notes[0],
              style: styles[notes[0].id.hashCode % styles.length],
              tapeStyle: tapeStyles[notes[0].id.hashCode % tapeStyles.length],
              width: (width * 0.55).floorToDouble(),
              onTap: () => onNoteTap?.call(notes[0]),
            ),
          ),
        ),
      ],
    );
  }
}
