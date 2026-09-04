import 'dart:convert';

import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_api/planbook_api.dart';

class DatabaseTagApi {
  DatabaseTagApi({
    required this.db,
    required OutboxApi outboxApi,
  }) : _outboxApi = outboxApi;

  final AppDatabase db;
  final OutboxApi _outboxApi;

  Future<bool> hasPendingChanges(String tagId) => _outboxApi.hasPending(tagId);

  Future<int> getTotalCount({required String? userId}) async {
    final query = db.selectOnly(db.tags, distinct: true)
      ..addColumns([db.tags.id.count()])
      ..where(
        db.tags.deletedAt.isNull() &
            (userId == null
                ? db.tags.userId.isNull()
                : db.tags.userId.equals(userId)),
      );
    final result = await query.getSingleOrNull();
    return result?.read(db.tags.id.count()) ?? 0;
  }

  Future<void> insertOrUpdateTag(Tag tag) async {
    await db.into(db.tags).insertOnConflictUpdate(tag.toCompanion(false));
  }

  Future<void> insertOrUpdateTaskTag(TaskTag taskTag) async {
    await db
        .into(db.taskTags)
        .insertOnConflictUpdate(taskTag.toCompanion(false));
  }

  Future<Tag?> getTagById(String id) async {
    return (db.select(
      db.tags,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<TagEntity>> getTopLevelTags({String? userId}) {
    return (db.select(
            db.tags,
          )
          ..where(
            (tag) =>
                tag.deletedAt.isNull() &
                tag.parentId.isNull() &
                (userId == null
                    ? tag.userId.isNull()
                    : tag.userId.equals(userId)),
          )
          ..orderBy([
            (tag) => OrderingTerm.asc(tag.order),
            (tag) => OrderingTerm.asc(tag.createdAt),
            (tag) => OrderingTerm.asc(tag.level),
          ]))
        .watch()
        .map(
          (tags) {
            final tagMap = Map<String, Tag>.fromEntries(
              tags.map((tag) => MapEntry(tag.id, tag)),
            );

            final entities = <String, TagEntity>{};
            for (final tag in tags) {
              if (tag.parentId == null) {
                entities[tag.id] = _buildTagEntity(tag, tagMap);
              }
            }
            return entities.values.toList();
          },
        );
  }

  TagEntity _buildTagEntity(
    Tag tag,
    Map<String, Tag> allTags, {
    Set<String> ancestorIds = const {},
  }) {
    final nextAncestorIds = {...ancestorIds, tag.id};
    final parent = allTags[tag.parentId];
    return TagEntity(
      tag: tag,
      // 历史数据可能存在父子循环。遇到已访问节点时截断父链，避免整批标签读取失败。
      parent: parent != null && !nextAncestorIds.contains(parent.id)
          ? _buildTagEntity(
              parent,
              allTags,
              ancestorIds: nextAncestorIds,
            )
          : null,
    );
  }

  Stream<List<TagEntity>> getAllTags({
    Set<String> notIncludeTagIds = const {},
    String? userId,
  }) {
    return (db.select(
            db.tags,
          )
          ..where(
            (tag) =>
                tag.deletedAt.isNull() &
                tag.id.isNotIn(notIncludeTagIds) &
                (userId == null
                    ? tag.userId.isNull()
                    : tag.userId.equals(userId)),
          )
          ..orderBy([
            (tag) => OrderingTerm.asc(tag.level),
            (tag) => OrderingTerm.asc(tag.order),
            (tag) => OrderingTerm.asc(tag.createdAt),
          ]))
        .watch()
        .map(
          (tags) {
            final tagMap = Map<String, Tag>.fromEntries(
              tags.map((tag) => MapEntry(tag.id, tag)),
            );
            final entities = <TagEntity>[];
            for (final tag in tags) {
              final entity = _buildTagEntity(tag, tagMap);
              final index = entities.indexWhere((e) => e.id == entity.parentId);
              if (index != -1) {
                entities.insert(index + 1, entity);
              } else {
                entities.add(entity);
              }
            }
            return entities;
          },
        );
  }

  Future<TagEntity?> getTagEntityById(String id) {
    return _getTagEntityById(id, <String>{});
  }

  Future<TagEntity?> _getTagEntityById(
    String id,
    Set<String> visitedIds,
  ) async {
    if (!visitedIds.add(id)) return null;
    final tag =
        await (db.select(
              db.tags,
            )..where((tag) => tag.id.equals(id) & tag.deletedAt.isNull()))
            .getSingleOrNull();
    if (tag == null) return null;
    var entity = TagEntity(tag: tag);
    if (tag.parentId != null) {
      final parent = await _getTagEntityById(tag.parentId!, visitedIds);
      if (parent != null) entity = entity.copyWith(parent: parent);
    }
    return entity;
  }

  Future<TagEntity?> getTagEntityByName(String name, String? userId) async {
    final trimmedName = name.trim();
    final tags =
        await (db.select(
              db.tags,
            )..where(
              (tag) =>
                  tag.name.equals(trimmedName) &
                  tag.deletedAt.isNull() &
                  (userId == null
                      ? tag.userId.isNull()
                      : tag.userId.equals(userId)),
            ))
            .get();
    if (tags.isEmpty) return null;
    var entity = TagEntity(tag: tags.first);
    if (tags.first.parentId != null) {
      final parent = await _getTagEntityById(
        tags.first.parentId!,
        {tags.first.id},
      );
      if (parent != null) entity = entity.copyWith(parent: parent);
    }
    return entity;
  }

  /// 返回标签自身及其全部后代 ID，供父标签选择器排除非法选项。
  Future<Set<String>> getTagAndDescendantIds({
    required String id,
    required String? userId,
  }) async {
    final tags =
        await (db.select(db.tags)..where(
              (tag) =>
                  tag.deletedAt.isNull() &
                  (userId == null
                      ? tag.userId.isNull()
                      : tag.userId.equals(userId)),
            ))
            .get();
    final childIdsByParentId = <String, List<String>>{};
    for (final tag in tags) {
      final parentId = tag.parentId;
      if (parentId == null) continue;
      childIdsByParentId.putIfAbsent(parentId, () => []).add(tag.id);
    }

    final result = <String>{};
    final pendingIds = <String>[id];
    while (pendingIds.isNotEmpty) {
      final currentId = pendingIds.removeLast();
      if (!result.add(currentId)) continue;
      pendingIds.addAll(childIdsByParentId[currentId] ?? const []);
    }
    return result;
  }

  /// 判断把 [tagId] 移到 [parentId] 下是否会形成父子循环。
  Future<bool> wouldCreateHierarchyCycle({
    required String tagId,
    required String? parentId,
  }) async {
    if (parentId == null) return false;

    final visitedIds = <String>{tagId};
    String? currentId = parentId;
    while (currentId != null) {
      if (!visitedIds.add(currentId)) return true;
      final current = await getTagById(currentId);
      if (current == null || current.deletedAt != null) return false;
      currentId = current.parentId;
    }
    return false;
  }

  /// 修复同步下来的历史循环数据，并重新计算受影响标签的层级。
  ///
  /// 一个标签只能有一个父标签，因此每个环只需断开一条边。这里选择最后更新的
  /// 标签恢复为顶级标签，通常就是导致成环的最后一次移动操作。
  Future<int> repairHierarchyCycles({required String? userId}) async {
    final tags =
        await (db.select(db.tags)..where(
              (tag) =>
                  tag.deletedAt.isNull() &
                  (userId == null
                      ? tag.userId.isNull()
                      : tag.userId.equals(userId)),
            ))
            .get();
    final originalTags = {for (final tag in tags) tag.id: tag};
    final repairedTags = Map<String, Tag>.of(originalTags);
    final changedIds = <String>{};
    final handledIds = <String>{};
    final now = Jiffy.now();

    for (final startTag in tags) {
      if (handledIds.contains(startTag.id)) continue;
      final path = <String>[];
      final pathIndexes = <String, int>{};
      String? currentId = startTag.id;

      while (currentId != null && repairedTags.containsKey(currentId)) {
        final cycleStartIndex = pathIndexes[currentId];
        if (cycleStartIndex != null) {
          final cycleIds = path.sublist(cycleStartIndex);
          final idToDetach = cycleIds.reduce((latestId, candidateId) {
            final latest = repairedTags[latestId]!;
            final candidate = repairedTags[candidateId]!;
            final latestAt = (latest.updatedAt ?? latest.createdAt).dateTime;
            final candidateAt = (candidate.updatedAt ?? candidate.createdAt)
                .dateTime;
            final comparison = candidateAt.compareTo(latestAt);
            if (comparison != 0) {
              return comparison > 0 ? candidateId : latestId;
            }
            return candidateId.compareTo(latestId) > 0
                ? candidateId
                : latestId;
          });
          repairedTags[idToDetach] = repairedTags[idToDetach]!.copyWith(
            parentId: const Value(null),
            level: 0,
            updatedAt: Value(now),
          );
          changedIds.add(idToDetach);
          break;
        }
        if (handledIds.contains(currentId)) break;

        pathIndexes[currentId] = path.length;
        path.add(currentId);
        currentId = repairedTags[currentId]!.parentId;
      }
      handledIds.addAll(path);
    }

    if (changedIds.isEmpty) return 0;

    final resolvedLevels = <String, int>{};
    int resolveLevel(String id) {
      final cached = resolvedLevels[id];
      if (cached != null) return cached;
      final parentId = repairedTags[id]?.parentId;
      final level = parentId == null || !repairedTags.containsKey(parentId)
          ? 0
          : resolveLevel(parentId) + 1;
      resolvedLevels[id] = level;
      return level;
    }

    for (final id in repairedTags.keys) {
      final tag = repairedTags[id]!;
      final expectedLevel = resolveLevel(id);
      if (tag.level == expectedLevel) continue;
      repairedTags[id] = tag.copyWith(
        level: expectedLevel,
        updatedAt: Value(now),
      );
      changedIds.add(id);
    }

    for (final id in changedIds) {
      await update(tag: repairedTags[id]!);
    }
    return changedIds.length;
  }

  Future<List<TagEntity>> getTagEntitiesByTaskId(
    String taskId,
    String? userId,
  ) async {
    final taskTags =
        await (db.select(db.taskTags)
              ..where(
                (tt) =>
                    tt.taskId.equals(taskId) &
                    tt.deletedAt.isNull() &
                    tt.linkedTagId.isNull() &
                    (userId == null
                        ? tt.userId.isNull()
                        : tt.userId.equals(userId)),
              )
              ..orderBy([
                (tt) => OrderingTerm.asc(tt.createdAt.datetime),
              ]))
            .get();

    final tags = await Future.wait(
      taskTags.map((t) => getTagEntityById(t.tagId)),
    );

    return tags.nonNulls.toList();
  }

  Future<void> create({
    required Tag tag,
  }) async {
    await db.transaction(() async {
      await db.into(db.tags).insert(tag.toCompanion(false));
      await _outboxApi.enqueue(
        tableName: 'tags',
        recordId: tag.id,
        operation: 'insert',
        payload: jsonEncode(tag.toJson()),
      );
    });
  }

  Future<void> update({
    required Tag tag,
  }) async {
    await db.transaction(() async {
      await (db.update(
        db.tags,
      )..where((t) => t.id.equals(tag.id))).write(
        tag.toCompanion(false),
      );
      await _outboxApi.enqueue(
        tableName: 'tags',
        recordId: tag.id,
        operation: 'update',
        payload: jsonEncode(tag.toJson()),
      );
    });

    // TODO: update task tags and note tags
  }

  Future<void> updateTag({
    required String id,
    String? name,
    ColorScheme? lightColorScheme,
    ColorScheme? darkColorScheme,
    TagEntity? parentTag,
  }) async {
    final tag = await getTagEntityById(id);
    if (tag == null) return;

    final trimmedName = name?.trim() ?? tag.name.trim();
    await db.transaction(() async {
      await (db.update(
        db.tags,
      )..where((tag) => tag.id.equals(id) & tag.deletedAt.isNull())).write(
        TagsCompanion(
          name: Value(trimmedName),
          level: parentTag != null
              ? Value(parentTag.level + 1)
              : const Value.absent(),
          parentId: parentTag != null
              ? Value(parentTag.id)
              : const Value.absent(),
          lightColorScheme: lightColorScheme != null
              ? Value(lightColorScheme)
              : const Value.absent(),
          darkColorScheme: darkColorScheme != null
              ? Value(darkColorScheme)
              : const Value.absent(),
        ),
      );
      final updatedTag = await (db.select(
        db.tags,
      )..where((t) => t.id.equals(id))).getSingle();
      await _outboxApi.enqueue(
        tableName: 'tags',
        recordId: id,
        operation: 'update',
        payload: jsonEncode(updatedTag.toJson()),
      );
    });
  }

  /// 递归删除 tag 及其所有子 tag
  Future<void> deleteById(String id) async {
    final now = Jiffy.now();

    // 标记当前 tag 为删除
    await (db.update(
      db.tags,
    )..where((tag) => tag.id.equals(id) & tag.deletedAt.isNull())).write(
      TagsCompanion(
        deletedAt: Value(now),
      ),
    );

    // 删除相关的 TaskTag 记录（软删除）
    await (db.update(db.taskTags)..where(
          (tt) => tt.tagId.equals(id) & tt.deletedAt.isNull(),
        ))
        .write(
          TaskTagsCompanion(
            deletedAt: Value(now),
          ),
        );

    // 删除相关的 NoteTag 记录（软删除）
    await (db.update(db.noteTags)..where(
          (nt) => nt.tagId.equals(id) & nt.deletedAt.isNull(),
        ))
        .write(
          NoteTagsCompanion(
            deletedAt: Value(now),
          ),
        );

    // 查找所有直接子 tag，递归删除
    final directChildren =
        await (db.select(
              db.tags,
            )..where(
              (tag) => tag.parentId.equals(id) & tag.deletedAt.isNull(),
            ))
            .get();

    for (final child in directChildren) {
      await deleteById(child.id);
    }
  }

  Future<void> deleteTagById(String id) async {
    if (kDebugMode) {
      await (db.delete(db.tags)..where(
            (t) => t.id.equals(id),
          ))
          .go();
    } else {
      await deleteById(id);
    }
    await db.transaction(() async {
      await _outboxApi.enqueue(
        tableName: 'tags',
        recordId: id,
        operation: 'delete',
        payload: jsonEncode({'id': id}),
      );
    });
  }

  Future<void> deleteAllTags() async {
    if (kDebugMode) {
      await db.delete(db.tags).go();
    }
  }

  Future<List<TaskTag>> getTaskTagsByTaskId(
    String taskId,
    String? userId,
  ) async {
    return (db.select(db.taskTags)..where(
          (tt) =>
              tt.taskId.equals(taskId) &
              tt.deletedAt.isNull() &
              (userId == null ? tt.userId.isNull() : tt.userId.equals(userId)),
        ))
        .get();
  }

  Future<List<NoteTag>> getNoteTagsByNoteId(
    String noteId,
    String? userId,
  ) async {
    return (db.select(db.noteTags)..where(
          (nt) =>
              nt.noteId.equals(noteId) &
              nt.deletedAt.isNull() &
              (userId == null ? nt.userId.isNull() : nt.userId.equals(userId)),
        ))
        .get();
  }

  /// 按关键词搜索标签（名称）
  Future<List<TagEntity>> searchTagEntities({
    required String query,
    required String? userId,
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final pattern = '%${_escapeLikePattern(trimmed)}%';
    final tags =
        await (db.select(db.tags)
              ..where(
                (tag) =>
                    tag.deletedAt.isNull() &
                    tag.name.like(pattern, escapeChar: r'\') &
                    (userId == null
                        ? tag.userId.isNull()
                        : tag.userId.equals(userId)),
              )
              ..orderBy([
                (tag) => OrderingTerm.asc(tag.level),
                (tag) => OrderingTerm.asc(tag.order),
                (tag) => OrderingTerm.asc(tag.createdAt),
              ])
              ..limit(limit))
            .get();

    final results = <TagEntity>[];
    for (final tag in tags) {
      final entity = await getTagEntityById(tag.id);
      if (entity != null) results.add(entity);
    }
    return results;
  }
}

String _escapeLikePattern(String input) {
  return input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
