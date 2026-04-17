import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_core/view/flip_page_view.dart';

@immutable
final class JournalDate {
  const JournalDate({
    required this.year,
    required this.month,
    required this.day,
  });

  factory JournalDate.fromYear(int year, {FlipPageIndex? pageIndex}) {
    if (pageIndex == null) {
      return JournalDate(year: year, month: 1, day: null);
    }
    if (pageIndex.left < 0) {
      return JournalDate(year: year, month: 1, day: null);
    }
    final startOfYear = Jiffy.parseFromList([year]);
    final daysInYear = startOfYear
        .add(years: 1)
        .diff(startOfYear, unit: Unit.day)
        .toInt();
    if (pageIndex.right >= daysInYear * 2) {
      return JournalDate(year: year, month: 12, day: null);
    }
    final date = startOfYear.add(days: pageIndex.left ~/ 2);
    return JournalDate.fromJiffy(date);
  }

  factory JournalDate.fromJiffy(Jiffy date) => JournalDate(
    year: date.year,
    month: date.month,
    day: date.date,
  );

  final int year;
  final int month;
  final int? day;

  JournalDate get cover => JournalDate(year: year, month: 1, day: null);
  JournalDate get backCover => JournalDate(year: year, month: 12, day: null);

  JournalDate get previous {
    if (isCoverPage) return JournalDate(year: year - 1, month: 12, day: 31);
    if (isBackCoverPage) return JournalDate(year: year, month: 12, day: 31);
    if (month == 1 && day == 1) return cover;
    final date = Jiffy.parseFromList([year, month, day! - 1]);
    return JournalDate.fromJiffy(date);
  }

  JournalDate get next {
    if (isCoverPage) return JournalDate(year: year, month: 1, day: 1);
    if (isBackCoverPage) {
      return JournalDate(year: year + 1, month: 1, day: 1);
    }
    if (month == 12 && day == 31) return backCover;
    final date = Jiffy.parseFromList([year, month, day! + 1]);
    return JournalDate.fromJiffy(date);
  }

  bool get isCoverPage => month == 1 && day == null;
  bool get isBackCoverPage => month == 12 && day == null;
  FlipPageIndex get pageIndex {
    if (isCoverPage) return FlipPageIndex.cover;
    if (isBackCoverPage) return FlipPageIndex.fromLeft(daysInYear * 2);
    final date = Jiffy.parseFromList([year, month, day!]);
    return FlipPageIndex.fromLeft(
      date.diff(startOfYear, unit: Unit.day).toInt() * 2,
    );
  }

  Jiffy get date {
    if (isCoverPage) return startOfYear;
    if (isBackCoverPage) return endOfYear;
    return Jiffy.parseFromMap({
      Unit.year: year,
      Unit.month: month,
      Unit.day: day ?? 1,
    });
  }

  Jiffy get startOfYear => Jiffy.parseFromList([year]);
  Jiffy get endOfYear => Jiffy.parseFromList([year, 12, 31, 23, 59, 59, 999]);

  int get daysInYear {
    final startOfYear = Jiffy.parseFromList([year]);
    return startOfYear.add(years: 1).diff(startOfYear, unit: Unit.day).toInt();
  }

  JournalDate copyWith({
    int? year,
    int? month,
    ValueGetter<int?>? day,
  }) => JournalDate(
    year: year ?? this.year,
    month: month ?? this.month,
    day: day == null ? this.day : day.call(),
  );

  @override
  String toString() => 'JournalDate(year: $year, month: $month, day: $day)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;
}
