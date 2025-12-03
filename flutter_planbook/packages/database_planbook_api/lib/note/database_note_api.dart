import 'dart:collection';

import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class DatabaseNoteApi {
  DatabaseNoteApi({
    required this.db,
    required this.tagApi,
  });

  final AppDatabase db;
  final DatabaseTagApi tagApi;

  Future<String> create({
    required String title,
    String? content,
    List<String>? images,
    List<Tag>? tags,
    String? taskId,
  }) async {
    final noteCompanion = NotesCompanion.insert(
      title: title,
      content: Value(content),
      images: Value(images ?? []),
      taskId: Value(taskId),
    );
    final note = await db.into(db.notes).insertReturning(noteCompanion);

    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        await db
            .into(db.noteTags)
            .insert(
              NoteTagsCompanion.insert(
                noteId: note.id,
                tagId: tag.id,
              ),
            );
      }
    }
    return note.id;
  }

  Future<void> update({
    required Note note,
    List<Tag>? tags,
  }) async {
    await (db.update(
      db.notes,
    )..where((n) => n.id.equals(note.id))).write(note.toCompanion(false));
    if (tags != null) {
      // 获取当前 note 的所有 tags（排除已删除的）
      final currentNoteTags =
          await (db.select(
                db.noteTags,
              )..where(
                (nt) => nt.noteId.equals(note.id) & nt.deletedAt.isNull(),
              ))
              .get();
      final currentTagIds = currentNoteTags
          .map((nt) => nt.tagId)
          .whereType<String>()
          .toSet();
      final newTagIds = tags.map((tag) => tag.id).toSet();

      // 找出需要添加的 tags（新 tags 中有，旧 tags 中没有）
      final tagsToAdd = newTagIds.difference(currentTagIds);
      for (final tagId in tagsToAdd) {
        await db
            .into(db.noteTags)
            .insert(
              NoteTagsCompanion.insert(
                noteId: note.id,
                tagId: tagId,
              ),
            );
      }

      // 找出需要删除的 tags（旧 tags 中有，新 tags 中没有）
      // 使用软删除：设置 deletedAt 字段
      final tagsToDelete = currentTagIds.difference(newTagIds);
      if (tagsToDelete.isNotEmpty) {
        await (db.update(db.noteTags)..where(
              (nt) =>
                  nt.noteId.equals(note.id) &
                  nt.tagId.isIn(tagsToDelete) &
                  nt.deletedAt.isNull(),
            ))
            .write(
              NoteTagsCompanion(
                deletedAt: Value(Jiffy.now()),
              ),
            );
      }
    }
  }

  Future<NoteEntity?> getNoteEntityById(String noteId) async {
    final rows =
        await (db.select(db.notes).join([
              leftOuterJoin(
                db.tasks,
                db.tasks.id.equalsExp(db.notes.taskId) &
                    db.tasks.deletedAt.isNull(),
              ),
              leftOuterJoin(
                db.noteTags,
                db.noteTags.noteId.equalsExp(db.notes.id) &
                    db.noteTags.deletedAt.isNull(),
              ),
            ])..where(
              db.notes.id.equals(noteId) & db.notes.deletedAt.isNull(),
            ))
            .get();
    final entities = await buildNoteEntities(rows);
    return entities.firstOrNull;
  }

  Stream<List<NoteEntity>> getNoteEntitiesByTaskId(String taskId) {
    return (db.select(db.notes).join([
            leftOuterJoin(
              db.tasks,
              db.tasks.id.equalsExp(db.notes.taskId) &
                  db.tasks.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.noteTags,
              db.noteTags.noteId.equalsExp(db.notes.id) &
                  db.noteTags.deletedAt.isNull(),
            ),
          ])
          ..where(
            db.notes.taskId.equals(taskId) & db.notes.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.desc(db.notes.createdAt.datetime)]))
        .watch()
        .asyncMap(buildNoteEntities);
  }

  Stream<List<NoteEntity>> getNoteEntitiesByTagId(String tagId) {
    return (db.select(db.notes).join([
            leftOuterJoin(
              db.tasks,
              db.tasks.id.equalsExp(db.notes.taskId) &
                  db.tasks.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.noteTags,
              db.noteTags.noteId.equalsExp(db.notes.id) &
                  db.noteTags.deletedAt.isNull(),
            ),
          ])
          ..where(
            db.noteTags.tagId.equals(tagId) & db.notes.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.desc(db.notes.createdAt.datetime)]))
        .watch()
        .asyncMap(buildNoteEntities);
  }

  Future<List<NoteEntity>> buildNoteEntities(List<TypedResult> rows) async {
    final notesMap = <String, Note>{};
    final tagsByNoteId = <String, List<TagEntity>>{};
    final taskMap = <String, Task>{};
    for (final row in rows) {
      final note = row.readTable(db.notes);
      notesMap[note.id] = note;

      // 获取 Tag
      final noteTag = row.readTableOrNull(db.noteTags);
      if (noteTag != null) {
        final tag = await tagApi.getTagEntityById(noteTag.tagId);
        if (tag != null) {
          tagsByNoteId.putIfAbsent(note.id, () => []).add(tag);
        }
      }

      final task = row.readTableOrNull(db.tasks);
      if (task != null) {
        taskMap[note.id] = task;
      }
    }
    return notesMap.values
        .map(
          (note) => NoteEntity(
            note: note,
            tags: tagsByNoteId[note.id] ?? [],
            task: taskMap[note.id],
          ),
        )
        .toList();
  }

  Stream<List<NoteEntity>> getNoteEntitiesByDate(
    Jiffy date, {
    List<String>? tagIds,
  }) {
    final startOfDay = date.startOf(Unit.day);
    final endOfDay = date.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.dateTime;
    final endOfDayDateTime = endOfDay.dateTime;

    var exp =
        db.notes.deletedAt.isNull() &
        db.notes.createdAt.isBiggerOrEqualValue(
          startOfDayDateTime,
        ) &
        db.notes.createdAt.isSmallerOrEqualValue(
          endOfDayDateTime,
        );
    if (tagIds != null && tagIds.isNotEmpty) {
      exp &= db.noteTags.tagId.isIn(tagIds);
    }

    return (db.select(db.notes).join(
            [
              leftOuterJoin(
                db.tasks,
                db.tasks.id.equalsExp(db.notes.taskId) &
                    db.tasks.deletedAt.isNull(),
              ),
              leftOuterJoin(
                db.noteTags,
                db.noteTags.noteId.equalsExp(db.notes.id) &
                    db.noteTags.isParent.equals(false) &
                    db.noteTags.deletedAt.isNull(),
              ),
            ],
          )
          ..where(exp)
          ..orderBy([OrderingTerm.desc(db.notes.createdAt.datetime)]))
        .watch()
        .asyncMap(buildNoteEntities);
  }

  Stream<List<NoteImageEntity>> getNoteImageEntities(int year) {
    return (db.select(
          db.notes,
        )..where((n) => n.deletedAt.isNull() & n.createdAt.year.equals(year)))
        .watch()
        .asyncMap((notes) {
          final images = <NoteImageEntity>[];
          for (final note in notes) {
            for (final image in note.images) {
              images.add(
                NoteImageEntity(
                  id: image,
                  image: image,
                  createdAt: note.createdAt,
                ),
              );
            }
          }
          return images;
        });
  }

  Stream<List<NoteEntity>> getWrittenNoteEntities(
    Jiffy date, {
    List<String>? tagIds,
  }) {
    final startOfDay = date.startOf(Unit.day);
    final endOfDay = date.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.toUtc().dateTime;
    final endOfDayDateTime = endOfDay.toUtc().dateTime;

    var exp =
        db.notes.deletedAt.isNull() &
        db.notes.createdAt.isBiggerOrEqualValue(
          startOfDayDateTime,
        ) &
        db.notes.createdAt.isSmallerOrEqualValue(
          endOfDayDateTime,
        ) &
        (db.tasks.id.isNull() |
            db.tasks.deletedAt.isNotNull() |
            (db.notes.images.isNotNull() & db.notes.images.equals('[]').not()) |
            (db.notes.content.isNotNull() & db.notes.content.equals('').not()));
    if (tagIds != null && tagIds.isNotEmpty) {
      exp &= db.noteTags.tagId.isIn(tagIds);
    }
    return (db.select(db.notes).join([
            leftOuterJoin(
              db.tasks,
              db.tasks.id.equalsExp(db.notes.taskId) &
                  db.tasks.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.noteTags,
              db.noteTags.noteId.equalsExp(db.notes.id) &
                  db.noteTags.isParent.equals(false) &
                  db.noteTags.deletedAt.isNull(),
            ),
          ])
          ..where(exp)
          ..orderBy([OrderingTerm.asc(db.notes.createdAt.datetime)]))
        .watch()
        .asyncMap(buildNoteEntities);
  }

  Future<Jiffy?> getStartDate() async {
    final row =
        await (db.select(
                db.notes,
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt.datetime)])
              ..limit(1))
            .getSingleOrNull();
    return row?.createdAt;
  }
}
