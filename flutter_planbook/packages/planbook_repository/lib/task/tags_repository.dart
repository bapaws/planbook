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
import 'package:planbook_repository/sync/apply_remote_batch.dart';
import 'package:planbook_repository/sync/database_pull_lock.dart';
import 'package:planbook_repository/sync/pull_sync_coordinator.dart';
import 'package:planbook_repository/sync/pull_write_fence.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/tag/supabase_tag_api.dart';
import 'package:uuid/uuid.dart';

/// 标签移动后会形成父子循环。
final class TagHierarchyCycleException implements Exception {
  const TagHierarchyCycleException();
}

class TagsRepository {
  TagsRepository({
    required AppDatabase db,
    required DatabaseTagApi tagApi,
    required SharedPreferences sp,
  }) : _tagApi = tagApi,
       _db = db,
       _supabaseTagApi = SupabaseTagApi(sp: sp);

  final DatabaseTagApi _tagApi;
  final AppDatabase _db;
  final SupabaseTagApi _supabaseTagApi;

  String? get userId => AppSupabase.client?.auth.currentUser?.id;

  Future<int> getTotalCount() => _tagApi.getTotalCount(userId: userId);

  Stream<List<TagEntity>> getTopLevelTags() {
    return _tagApi.getTopLevelTags(userId: userId);
  }

  Stream<List<TagEntity>> getAllTags({
    Set<String> notIncludeTagIds = const {},
  }) async* {
    unawaited(
      syncTags().catchError((Object e, StackTrace st) {
        debugPrint('TagsRepository.syncTags failed: $e\n$st');
      }),
    );
    yield* _tagApi.getAllTags(
      notIncludeTagIds: notIncludeTagIds,
      userId: userId,
    );
  }

  Future<Set<String>> getTagAndDescendantIds(String id) {
    return _tagApi.getTagAndDescendantIds(id: id, userId: userId);
  }

  final _pullSync = PullSyncCoordinator();

  Future<void> syncTags({bool force = false}) {
    final account = userId;
    return _pullSync.run(
      userId: account,
      force: force,
      action: ({required force}) => DatabasePullLock.run(_db, () async {
        void validateAccount() {
          if (userId != account) throw StateError('标签同步账号已变化');
        }

        validateAccount();
        await _tagApi.repairHierarchyCycles(userId: account);
        final fence = await PullWriteFence.capture(_db);
        final batch = await _supabaseTagApi.getLatestTagRows(force: force);
        validateAccount();
        if (batch != null) {
          await applyRemoteBatch(
            db: _db,
            batch: batch,
            fence: fence,
            account: account!,
            validateAccount: validateAccount,
          );
        }
        await _tagApi.repairHierarchyCycles(userId: account);
        validateAccount();
      }),
    );
  }

  Future<TagEntity?> getTagEntityById(String id) async {
    return _tagApi.getTagEntityById(id);
  }

  Future<TagEntity?> getTagEntityByName(String name) async {
    return _tagApi.getTagEntityByName(name, userId);
  }

  /// 按关键词搜索标签（名称）
  Future<List<TagEntity>> search(String query) {
    return _tagApi.searchTagEntities(query: query, userId: userId);
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

    if (id != null && parentTag != null) {
      final createsCycle = await _tagApi.wouldCreateHierarchyCycle(
        tagId: id,
        parentId: parentTag.id,
      );
      if (createsCycle) throw const TagHierarchyCycleException();
    }

    final tag = Tag(
      id: id ?? const Uuid().v4(),
      name: trimmedName,
      lightColorScheme: lightColorScheme,
      darkColorScheme: darkColorScheme,
      parentId: parentTag?.id,
      userId: userId,
      order: 0,
      level: (parentTag?.level ?? -1) + 1,
      createdAt: Jiffy.now(),
    );
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

    if (parentTag != null) {
      final createsCycle = await _tagApi.wouldCreateHierarchyCycle(
        tagId: id,
        parentId: parentTag.id,
      );
      if (createsCycle) throw const TagHierarchyCycleException();
    }

    final newTag = tag.copyWith(
      name: name?.trim(),
      lightColorScheme: Value(lightColorScheme),
      darkColorScheme: Value(darkColorScheme),
      parentId: Value(parentTag?.id),
      level: (parentTag?.level ?? -1) + 1,
      updatedAt: Value(Jiffy.now()),
    );
    await _tagApi.update(tag: newTag);
  }

  /// 递归删除 tag 及其所有子 tag
  Future<void> deleteById(String id) async {
    await _tagApi.deleteById(id);
  }

  Future<void> deleteAllTags() async {
    await _tagApi.deleteAllTags();
  }

  Future<void> createDefaultTags({required String languageCode}) async {
    final tagJsonString = await rootBundle.loadString(
      'assets/${kDebugMode ? 'demo' : 'files'}/tags_$languageCode.json',
    );
    final tagJson = jsonDecode(tagJsonString) as List<dynamic>;

    const uuid = Uuid();
    for (final json in tagJson) {
      final tag = Tag.fromJson(json as Map<String, dynamic>);
      final color = tag.color?.toColor ?? material.Colors.yellow;

      await createTag(
        id: kDebugMode ? null : uuid.v4(),
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
