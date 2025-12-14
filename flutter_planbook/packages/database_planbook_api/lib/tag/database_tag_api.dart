import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_api/planbook_api.dart';

class DatabaseTagApi {
  DatabaseTagApi({
    required this.db,
  });

  final AppDatabase db;

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

  TagEntity _buildTagEntity(Tag tag, Map<String, Tag> allTags) {
    final parent = allTags[tag.parentId];
    return TagEntity(
      tag: tag,
      parent: parent != null ? _buildTagEntity(parent, allTags) : null,
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

  Future<TagEntity?> getTagEntityById(String id) async {
    final tag =
        await (db.select(
              db.tags,
            )..where((tag) => tag.id.equals(id) & tag.deletedAt.isNull()))
            .getSingleOrNull();
    if (tag == null) return null;
    var entity = TagEntity(tag: tag);
    if (tag.parentId != null) {
      final parent = await getTagEntityById(tag.parentId!);
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
      final parent = await getTagEntityById(tags.first.parentId!);
      if (parent != null) entity = entity.copyWith(parent: parent);
    }
    return entity;
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
    await db.into(db.tags).insert(tag.toCompanion(false));
  }

  Future<void> update({
    required Tag tag,
  }) async {
    await (db.update(
      db.tags,
    )..where((t) => t.id.equals(tag.id))).write(
      tag.toCompanion(false),
    );

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
}
