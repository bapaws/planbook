import 'dart:convert';

import 'package:drift/drift.dart';

class ListConverter<T> extends TypeConverter<List<T>, String?>
    with JsonTypeConverter2<List<T>, String?, List<dynamic>?> {
  const ListConverter();

  @override
  List<T> fromSql(String? fromDb) {
    if (fromDb == null) return [];
    return List<T>.from(jsonDecode(fromDb) as List);
  }

  @override
  String? toSql(List<T>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  @override
  List<T> fromJson(List<dynamic>? json) {
    return json == null ? [] : List<T>.from(json);
  }

  @override
  List<dynamic>? toJson(List<T>? value) {
    return value ?? [];
  }
}
