import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class DatabaseTagApi {
  DatabaseTagApi({
    required AppDatabase db,
  }) : _db = db;

  final AppDatabase _db;

  Future<Stream<List<Tag>>> getTopLevelTags() async {
    return (_db.select(
      _db.tags,
    )..where((tag) => tag.parentId.isNull())).watch();
  }

  Stream<List<TagEntity>> getAllTags({
    Set<String> notIncludeTagIds = const {},
  }) {
    return (_db.select(
            _db.tags,
          )
          ..where(
            (tag) => tag.deletedAt.isNull() & tag.id.isNotIn(notIncludeTagIds),
          )
          ..orderBy([
            (tag) => OrderingTerm.asc(tag.order),
            (tag) => OrderingTerm.asc(tag.createdAt),
            (tag) => OrderingTerm.asc(tag.level),
          ]))
        .watch()
        .map(
          (tags) {
            final tagMap = <String, Tag>{};
            final entities = <String, TagEntity>{};
            for (final tag in tags) {
              tagMap[tag.id] = tag;
              if (tag.parentId != null) {
                entities[tag.id] = TagEntity(
                  tag: tag,
                  parent: entities[tag.parentId],
                );
              } else {
                entities[tag.id] = TagEntity(tag: tag);
              }
            }
            return entities.values.toList();
          },
        );
  }

  Future<TagEntity?> getTagEntityById(String id) async {
    final tag =
        await (_db.select(
              _db.tags,
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

  Future<TagEntity?> getTagEntityByName(String name) async {
    final trimmedName = name.trim();
    final tag =
        await (_db.select(
              _db.tags,
            )..where(
              (tag) => tag.name.equals(trimmedName) & tag.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (tag == null) return null;
    var entity = TagEntity(tag: tag);
    if (tag.parentId != null) {
      final parent = await getTagEntityById(tag.parentId!);
      if (parent != null) entity = entity.copyWith(parent: parent);
    }
    return entity;
  }

  Future<List<TagEntity>> getTagEntitiesByTaskId(String taskId) async {
    final taskTags =
        await (_db.select(_db.taskTags)
              ..where(
                (tt) =>
                    tt.taskId.equals(taskId) &
                    tt.deletedAt.isNull() &
                    tt.isParent.equals(false),
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

  Future<void> createTag({
    required String name,
    required ColorScheme lightColorScheme,
    required ColorScheme darkColorScheme,
    String? id,
    TagEntity? parentTag,
  }) async {
    final trimmedName = name.trim();
    final existingEntity = await getTagEntityByName(trimmedName);
    if (existingEntity != null) return;

    await _db
        .into(_db.tags)
        .insert(
          TagsCompanion.insert(
            id: id != null ? Value(id) : const Value.absent(),
            name: name,
            level: Value((parentTag?.level ?? -1) + 1),
            parentId: Value(parentTag?.id),
            lightColorScheme: Value(lightColorScheme),
            darkColorScheme: Value(darkColorScheme),
          ),
        );
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
    await (_db.update(
      _db.tags,
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
  Future<void> deleteTag(String id) async {
    final now = Jiffy.now();

    // 标记当前 tag 为删除
    await (_db.update(
      _db.tags,
    )..where((tag) => tag.id.equals(id) & tag.deletedAt.isNull())).write(
      TagsCompanion(
        deletedAt: Value(now),
      ),
    );

    // 删除相关的 TaskTag 记录（软删除）
    await (_db.update(_db.taskTags)..where(
          (tt) => tt.tagId.equals(id) & tt.deletedAt.isNull(),
        ))
        .write(
          TaskTagsCompanion(
            deletedAt: Value(now),
          ),
        );

    // 删除相关的 NoteTag 记录（软删除）
    await (_db.update(_db.noteTags)..where(
          (nt) => nt.tagId.equals(id) & nt.deletedAt.isNull(),
        ))
        .write(
          NoteTagsCompanion(
            deletedAt: Value(now),
          ),
        );

    // 查找所有直接子 tag，递归删除
    final directChildren =
        await (_db.select(
              _db.tags,
            )..where(
              (tag) => tag.parentId.equals(id) & tag.deletedAt.isNull(),
            ))
            .get();

    for (final child in directChildren) {
      await deleteTag(child.id);
    }
  }

  Future<void> deleteTagById(String id) async {
    if (kDebugMode) {
      await (_db.delete(_db.tags)..where(
            (t) => t.id.equals(id),
          ))
          .go();
    } else {
      await deleteTag(id);
    }
  }

  Future<void> deleteAllTags() async {
    if (kDebugMode) {
      await _db.delete(_db.tags).go();
    }
  }
}
