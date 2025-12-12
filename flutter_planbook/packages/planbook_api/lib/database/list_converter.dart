import 'dart:convert';

import 'package:drift/drift.dart';

class ListConverter<T> extends TypeConverter<List<T>, String?>
    with JsonTypeConverter2<List<T>, String?, String?> {
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
  List<T> fromJson(String? json) {
    if (json == null) return [];
    return List<T>.from(jsonDecode(json) as List);
  }

  @override
  String? toJson(List<T>? value) {
    return value == null ? null : jsonEncode(value);
  }
}
