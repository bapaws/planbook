import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';

class JiffyConverter extends TypeConverter<Jiffy, DateTime>
    with JsonTypeConverter2<Jiffy, DateTime, DateTime> {
  const JiffyConverter();

  @override
  Jiffy fromSql(DateTime value) => Jiffy.parseFromDateTime(value);

  @override
  DateTime toSql(Jiffy value) => value.toUtc().dateTime;

  @override
  Jiffy fromJson(DateTime json) => Jiffy.parseFromDateTime(json);

  @override
  DateTime toJson(Jiffy value) => value.toUtc().dateTime;
}
