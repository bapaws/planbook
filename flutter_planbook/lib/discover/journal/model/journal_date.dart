import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_core/view/flip_page_view.dart';

/// 日记翻页中每一页的语义类型。
enum JournalPageKind {
  cover,
  monthHighlight,
  day,
  monthSummary,
  backCover,
}

@immutable
final class JournalDate {
  const JournalDate({
    required this.year,
    required this.month,
    this.day,
    this.kind = JournalPageKind.day,
  });

  factory JournalDate.cover(int year) => JournalDate(
    year: year,
    month: 1,
    kind: JournalPageKind.cover,
  );

  factory JournalDate.backCover(int year) => JournalDate(
    year: year,
    month: 12,
    kind: JournalPageKind.backCover,
  );

  factory JournalDate.monthHighlight({
    required int year,
    required int month,
  }) => JournalDate(
    year: year,
    month: month,
    kind: JournalPageKind.monthHighlight,
  );

  factory JournalDate.monthSummary({
    required int year,
    required int month,
  }) => JournalDate(
    year: year,
    month: month,
    kind: JournalPageKind.monthSummary,
  );

  factory JournalDate.fromJiffy(Jiffy date) => JournalDate(
    year: date.year,
    month: date.month,
    day: date.date,
  );

  factory JournalDate.fromYear(
    int year, {
    FlipPageIndex? pageIndex,
  }) {
    if (pageIndex == null) return JournalDate.cover(year);

    final contentCount = JournalDate._contentPageCount(year);
    final alignedLeft = (pageIndex.left ~/ 2) * 2;

    if (alignedLeft < 0) return JournalDate.cover(year);
    if (pageIndex.right >= contentCount) {
      return JournalDate.backCover(year);
    }

    return JournalDate.fromContentIndex(year, alignedLeft);
  }

  /// 根据内容页索引反查 [JournalDate]。
  /// 内容页索引 0 对应 1 月的重点页左半页。
  factory JournalDate.fromContentIndex(int year, int contentIndex) {
    final contentCount = JournalDate._contentPageCount(year);
    if (contentIndex < 0) return JournalDate.cover(year);
    if (contentIndex >= contentCount) return JournalDate.backCover(year);

    for (var month = 1; month <= 12; month++) {
      final monthStart = _monthStartContentIndex(year, month);
      final nextMonthStart = _monthStartContentIndex(year, month + 1);
      if (contentIndex >= nextMonthStart) continue;

      final daysInMonth = _daysInMonth(year, month);
      final highlightStart = monthStart;
      final summaryStart = monthStart + 2 + daysInMonth * 2;

      if (contentIndex >= highlightStart &&
          contentIndex <= highlightStart + 1) {
        return JournalDate.monthHighlight(year: year, month: month);
      }
      if (contentIndex >= summaryStart && contentIndex <= summaryStart + 1) {
        return JournalDate.monthSummary(year: year, month: month);
      }

      final day = (contentIndex - (monthStart + 2)) ~/ 2 + 1;
      return JournalDate(year: year, month: month, day: day);
    }

    return JournalDate.backCover(year);
  }

  final int year;
  final int month;
  final int? day;
  final JournalPageKind kind;

  bool get isCoverPage => kind == JournalPageKind.cover;
  bool get isBackCoverPage => kind == JournalPageKind.backCover;
  bool get isMonthHighlightPage => kind == JournalPageKind.monthHighlight;
  bool get isMonthSummaryPage => kind == JournalPageKind.monthSummary;
  bool get isDayPage => kind == JournalPageKind.day;

  Jiffy get date {
    if (isCoverPage) return startOfYear;
    if (isBackCoverPage) return endOfYear;
    if (isDayPage) return Jiffy.parseFromList([year, month, day!]);
    return monthStart;
  }

  /// 当前页所属月份的第一天。
  Jiffy get monthStart => Jiffy.parseFromList([year, month, 1]);

  Jiffy get startOfYear => Jiffy.parseFromList([year]);
  Jiffy get endOfYear => Jiffy.parseFromList([year, 12, 31, 23, 59, 59, 999]);

  int get daysInYear {
    final startOfYear = Jiffy.parseFromList([year]);
    return startOfYear.add(years: 1).diff(startOfYear, unit: Unit.day).toInt();
  }

  /// 全年内容页总数（不含封面/封底）。
  int get contentPageCount => _contentPageCount(year);

  /// 当前 spread 在内容页中的起始索引（左半页索引）。
  int get contentIndexStart {
    if (isCoverPage) return -2;
    if (isBackCoverPage) return contentPageCount;
    if (isMonthHighlightPage) return _monthStartContentIndex(year, month);
    if (isMonthSummaryPage) {
      final monthStart = _monthStartContentIndex(year, month);
      return monthStart + 2 + _daysInMonth(year, month) * 2;
    }
    return _monthStartContentIndex(year, month) + 2 + (day! - 1) * 2;
  }

  FlipPageIndex get pageIndex {
    if (isCoverPage) return FlipPageIndex.cover;
    return FlipPageIndex.fromLeft(contentIndexStart);
  }

  JournalDate get previous {
    if (isCoverPage) return JournalDate(year: year - 1, month: 12, day: 31);
    if (isBackCoverPage) {
      return JournalDate(year: year, month: 12, day: 31);
    }

    final prevIndex = contentIndexStart - 2;
    if (prevIndex < 0) return JournalDate.cover(year);
    return JournalDate.fromContentIndex(year, prevIndex);
  }

  JournalDate get next {
    if (isCoverPage) return JournalDate(year: year, month: 1, day: 1);
    if (isBackCoverPage) {
      return JournalDate(year: year + 1, month: 1, day: 1);
    }

    final nextIndex = contentIndexStart + 2;
    if (nextIndex >= contentPageCount) {
      return JournalDate.backCover(year);
    }
    return JournalDate.fromContentIndex(year, nextIndex);
  }

  JournalDate copyWith({
    int? year,
    int? month,
    ValueGetter<int?>? day,
    JournalPageKind? kind,
  }) => JournalDate(
    year: year ?? this.year,
    month: month ?? this.month,
    day: day == null ? this.day : day.call(),
    kind: kind ?? this.kind,
  );

  static int _daysBeforeMonth(int year, int month) {
    final startOfYear = Jiffy.parseFromList([year]);
    final firstDayOfMonth = Jiffy.parseFromList([year, month, 1]);
    return firstDayOfMonth.diff(startOfYear, unit: Unit.day).toInt();
  }

  static int _daysInMonth(int year, int month) {
    final firstDay = Jiffy.parseFromList([year, month, 1]);
    return firstDay.daysInMonth;
  }

  /// 某月重点页在内容页中的起始索引。
  /// [month] 可传入 13 作为年末哨兵，返回全年内容页总数。
  static int _monthStartContentIndex(int year, int month) {
    if (month <= 1) return 0;
    if (month > 12) {
      final startOfYear = Jiffy.parseFromList([year]);
      final daysInYear = startOfYear
          .add(years: 1)
          .diff(startOfYear, unit: Unit.day)
          .toInt();
      return 12 * 4 + daysInYear * 2;
    }
    return (month - 1) * 4 + _daysBeforeMonth(year, month) * 2;
  }

  static int _contentPageCount(int year) {
    return _monthStartContentIndex(year, 13);
  }

  @override
  String toString() =>
      'JournalDate(year: $year, month: $month, day: $day, kind: $kind)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day &&
          kind == other.kind;

  @override
  int get hashCode =>
      year.hashCode ^ month.hashCode ^ day.hashCode ^ kind.hashCode;
}
