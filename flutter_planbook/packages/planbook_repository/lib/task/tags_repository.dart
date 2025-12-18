import 'dart:async';
import 'dart:convert';

import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/tag/supabase_tag_api.dart';
import 'package:uuid/uuid.dart';

class TagsRepository {
  TagsRepository({
    required SharedPreferences sp,
    required DatabaseTagApi tagApi,
  }) : _tagApi = tagApi,
       _supabaseTagApi = SupabaseTagApi(sp: sp),
       _db = tagApi.db;

  final DatabaseTagApi _tagApi;
  final SupabaseTagApi _supabaseTagApi;
  final AppDatabase _db;

  String? get userId => AppSupabase.client?.auth.currentUser?.id;

  Future<int> getTotalCount() => _tagApi.getTotalCount(userId: userId);

  Stream<List<TagEntity>> getTopLevelTags() {
    return _tagApi.getTopLevelTags(userId: userId);
  }

  Stream<List<TagEntity>> getAllTags({
    Set<String> notIncludeTagIds = const {},
  }) async* {
    unawaited(_syncTags());
    yield* _tagApi.getAllTags(
      notIncludeTagIds: notIncludeTagIds,
      userId: userId,
    );
  }

  Future<void> _syncTags({
    bool force = false,
  }) async {
    final tags = await _supabaseTagApi.getLatestTags(force: force);
    await _db.transaction(() async {
      for (final tag in tags) {
        await _db.into(_db.tags).insertOnConflictUpdate(tag);
      }
    });
  }

  Future<TagEntity?> getTagEntityById(String id) async {
    return _tagApi.getTagEntityById(id);
  }

  Future<TagEntity?> getTagEntityByName(String name) async {
    return _tagApi.getTagEntityByName(name, userId);
  }

  Future<void> createTag({
    required String name,
    required ColorScheme lightColorScheme,
    required ColorScheme darkColorScheme,
    String? id,
    TagEntity? parentTag,
  }) async {
    final trimmedName = name.trim();
    final existingEntity = await _tagApi.getTagEntityByName(
      trimmedName,
      userId,
    );
    if (existingEntity != null) return;

    final tag = Tag(
      id: id ?? const Uuid().v4(),
      name: trimmedName,
      lightColorScheme: lightColorScheme,
      darkColorScheme: darkColorScheme,
      parentId: parentTag?.id,
      userId: userId,
      order: 0,
      level: (parentTag?.level ?? -1) + 1,
      createdAt: Jiffy.now().toUtc(),
    );
    await _supabaseTagApi.create(tag: tag);
    await _tagApi.create(tag: tag);
  }

  Future<void> updateTag({
    required String id,
    String? name,
    ColorScheme? lightColorScheme,
    ColorScheme? darkColorScheme,
    TagEntity? parentTag,
  }) async {
    final tag = await _tagApi.getTagById(id);
    if (tag == null) return;

    final newTag = tag.copyWith(
      name: name?.trim(),
      lightColorScheme: Value(lightColorScheme),
      darkColorScheme: Value(darkColorScheme),
      parentId: Value(parentTag?.id),
      level: (parentTag?.level ?? -1) + 1,
      updatedAt: Value(Jiffy.now().toUtc()),
    );
    await _supabaseTagApi.update(tag: newTag);
    await _tagApi.update(tag: newTag);
  }

  /// 递归删除 tag 及其所有子 tag
  Future<void> deleteById(String id) async {
    await _supabaseTagApi.deleteById(id);
    await _tagApi.deleteById(id);
  }

  Future<void> deleteAllTags() async {
    await _tagApi.deleteAllTags();
  }

  Future<void> createDefaultTags({required String languageCode}) async {
    final tagJsonString = await rootBundle.loadString(
      'assets/files/${kDebugMode ? 'demo_' : ''}tags_$languageCode.json',
    );
    final tagJson = jsonDecode(tagJsonString) as List<dynamic>;

    const uuid = Uuid();
    for (final json in tagJson) {
      final tag = Tag.fromJson(json as Map<String, dynamic>);
      final color = tag.color?.toColor ?? material.Colors.yellow;

      await createTag(
        id: kDebugMode ? tag.id : uuid.v4(),
        name: tag.name,
        lightColorScheme: ColorScheme.fromColorScheme(
          material.ColorScheme.fromSeed(
            seedColor: color,
          ),
        ),
        darkColorScheme: ColorScheme.fromColorScheme(
          material.ColorScheme.fromSeed(
            seedColor: color,
            brightness: material.Brightness.dark,
          ),
        ),
      );
    }
  }
}
