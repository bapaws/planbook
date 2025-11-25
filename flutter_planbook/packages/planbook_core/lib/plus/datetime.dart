import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

final List<String> _weekDays = DateFormat().dateSymbols.WEEKDAYS;
final Map<int, String> weekDays = {
  DateTime.sunday: _weekDays[0],
  DateTime.monday: _weekDays[1],
  DateTime.tuesday: _weekDays[2],
  DateTime.wednesday: _weekDays[3],
  DateTime.thursday: _weekDays[4],
  DateTime.friday: _weekDays[5],
  DateTime.saturday: _weekDays[6],
};
final List<String> _narrowWeekDays = DateFormat().dateSymbols.NARROWWEEKDAYS;
final Map<int, String> narrowWeekDays = {
  DateTime.sunday: _narrowWeekDays[0],
  DateTime.monday: _narrowWeekDays[1],
  DateTime.tuesday: _narrowWeekDays[2],
  DateTime.wednesday: _narrowWeekDays[3],
  DateTime.thursday: _narrowWeekDays[4],
  DateTime.friday: _narrowWeekDays[5],
  DateTime.saturday: _narrowWeekDays[6],
};

extension DateTimeX on DateTime {
  bool get isToday => isSameDay(DateTime.now());
  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));
  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  bool isSameYear(DateTime other) => year == other.year;

  int get dateKey => year * 10000 + month * 100 + day;

  Jiffy get jiffy => Jiffy.parseFromDateTime(this);
}

extension JiffyX on Jiffy {
  int get dateKey => year * 10000 + month * 100 + date;
}

extension IntX on int {
  Jiffy get jiffy => Jiffy.parseFromList(
    [
      this ~/ 10000,
      (this % 10000) ~/ 100,
      this % 100,
    ],
  );

  String get formattedDuration {
    var formatted = '';
    final hours = this ~/ 3600;
    final minutes = (this % 3600) ~/ 60;
    final seconds = this % 60;
    if (hours > 0) {
      formatted += '${hours}h';
    }
    if (minutes > 0) {
      formatted += '${minutes}m';
    }
    if (seconds > 0 && hours == 0) {
      formatted += '${seconds}s';
    }
    return formatted;
  }
}
