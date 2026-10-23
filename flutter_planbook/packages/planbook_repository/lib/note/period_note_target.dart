import 'package:flutter/foundation.dart' show immutable;
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

/// 沿用现有笔记查询的日/周/月边界，固定一次交互的目标周期。
@immutable
class PeriodNoteTarget {
  PeriodNoteTarget({required Jiffy date, required this.type})
    : start = date.startOf(type.unit),
      end = date.endOf(type.unit);

  final NoteType type;
  final Jiffy start;
  final Jiffy end;

  /// 周笔记仍存周一；周起始日可配置，取显示周期内的周一。
  Jiffy get focusAt {
    if (!type.isWeekly) return start;
    final day = start.dateTime;
    final offset = (DateTime.monday - day.weekday + 7) % 7;
    return Jiffy.parseFromDateTime(
      day.isUtc
          ? DateTime.utc(day.year, day.month, day.day + offset)
          : DateTime(day.year, day.month, day.day + offset),
    );
  }

  bool accepts(Note note) =>
      note.deletedAt == null &&
      note.type == type &&
      note.focusAt != null &&
      !note.focusAt!.isBefore(start) &&
      !note.focusAt!.isAfter(end);

  @override
  bool operator ==(Object other) =>
      other is PeriodNoteTarget &&
      type == other.type &&
      start.dateTime == other.start.dateTime &&
      end.dateTime == other.end.dateTime;

  @override
  int get hashCode => Object.hash(type, start.dateTime, end.dateTime);
}

/// null + ready 才代表已确认不存在，不能把尚未加载当作空笔记。
@immutable
class PeriodNoteSnapshot {
  const PeriodNoteSnapshot({
    required this.target,
    required this.note,
    required this.isReady,
  });

  final PeriodNoteTarget target;
  final Note? note;
  final bool isReady;

  bool get canWrite => isReady && (note == null || target.accepts(note!));

  @override
  bool operator ==(Object other) =>
      other is PeriodNoteSnapshot &&
      target == other.target &&
      note == other.note &&
      isReady == other.isReady;

  @override
  int get hashCode => Object.hash(target, note, isReady);
}
