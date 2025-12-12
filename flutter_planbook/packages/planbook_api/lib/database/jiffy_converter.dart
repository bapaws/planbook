import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';

class JiffyConverter extends TypeConverter<Jiffy, DateTime>
    with JsonTypeConverter2<Jiffy, DateTime, String> {
  const JiffyConverter();

  @override
  Jiffy fromSql(DateTime value) => Jiffy.parseFromDateTime(value);

  @override
  DateTime toSql(Jiffy value) => value.toUtc().dateTime;

  @override
  Jiffy fromJson(String json) => Jiffy.parse(json, isUtc: true);

  @override
  String toJson(Jiffy value) => value.toUtc().format();
}
