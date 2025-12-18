import 'dart:collection';

import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

class DatabaseNoteApi {
  DatabaseNoteApi({
    required this.db,
    required this.tagApi,
  });

  final AppDatabase db;
  final DatabaseTagApi tagApi;

  Future<int> getTotalCount({required String? userId}) async {
    final query = db.selectOnly(db.notes, distinct: true)
      ..addColumns([db.notes.id.count()])
      ..where(
        db.notes.deletedAt.isNull() &
            (userId == null
                ? db.notes.userId.isNull()
                : db.notes.userId.equals(userId)),
      );
    final result = await query.getSingleOrNull();
    return result?.read(db.notes.id.count()) ?? 0;
  }

  List<NoteTag> generateNoteTags({
    required String noteId,
    String? userId,
    List<TagEntity>? tags,
  }) {
    if (tags == null || tags.isEmpty) return [];

    final noteTags = <NoteTag>[];
    const uuid = Uuid();
    final now = Jiffy.now();
    for (final tag in tags) {
      noteTags.add(
        NoteTag(
          id: uuid.v4(),
          noteId: noteId,
          tagId: tag.id,
          userId: userId,
          createdAt: now.toUtc(),
        ),
      );
      var parent = tag.parent;
      while (parent != null) {
        noteTags.add(
          NoteTag(
            id: uuid.v4(),
            linkedTagId: tag.id,
            noteId: noteId,
            tagId: parent.id,
            userId: userId,
            createdAt: now.toUtc(),
          ),
        );
        parent = parent.parent;
      }
    }
    return noteTags;
  }

  Future<void> create({
    required Note note,
    required List<NoteTag> noteTags,
  }) async {
    await db.transaction(() async {
      await db.into(db.notes).insert(note);
      for (final noteTag in noteTags) {
        await db.into(db.noteTags).insert(noteTag);
      }
    });
  }

  Future<void> update({
    required Note note,
    required List<NoteTag> noteTags,
  }) async {
    await db.transaction(() async {
      await (db.update(
        db.notes,
      )..where((n) => n.id.equals(note.id))).write(note.toCompanion(false));

      await (db.delete(
        db.noteTags,
      )..where((nt) => nt.noteId.equals(note.id))).go();
      for (final noteTag in noteTags) {
        await db.into(db.noteTags).insert(noteTag.toCompanion(false));
      }
    });
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
                    db.noteTags.linkedTagId.isNull() &
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
                  db.noteTags.linkedTagId.isNull() &
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
    // 子查询：找出所有与该 tagId 关联的 noteId（包括直接关联和通过父级关联的）
    final noteIdsSubquery = db.selectOnly(db.noteTags)
      ..addColumns([db.noteTags.noteId])
      ..where(
        (db.noteTags.tagId.equals(tagId) |
                db.noteTags.linkedTagId.equals(tagId)) &
            db.noteTags.deletedAt.isNull(),
      );

    return (db.select(db.notes).join([
            leftOuterJoin(
              db.tasks,
              db.tasks.id.equalsExp(db.notes.taskId) &
                  db.tasks.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.noteTags,
              // 只获取直接关联的 tag（linkedTagId.isNull()），这样可以获取笔记的所有直接 tag
              db.noteTags.noteId.equalsExp(db.notes.id) &
                  db.noteTags.linkedTagId.isNull() &
                  db.noteTags.deletedAt.isNull(),
            ),
          ])
          // 使用子查询过滤符合条件的笔记
          ..where(
            db.notes.id.isInQuery(noteIdsSubquery) &
                db.notes.deletedAt.isNull(),
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
    NoteListMode mode = NoteListMode.all,
    List<String>? tagIds,
    String? userId,
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
        ) &
        (userId == null
            ? db.notes.userId.isNull()
            : db.notes.userId.equals(userId));
    if (tagIds != null && tagIds.isNotEmpty) {
      exp &= db.noteTags.tagId.isIn(tagIds);
    }

    if (mode == NoteListMode.written) {
      exp &= db.tasks.id.isNull();
    } else if (mode == NoteListMode.task) {
      exp &= db.tasks.id.isNotNull();
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
                    db.noteTags.linkedTagId.isNull() &
                    db.noteTags.deletedAt.isNull(),
              ),
            ],
          )
          ..where(exp)
          ..orderBy([OrderingTerm.desc(db.notes.createdAt.datetime)]))
        .watch()
        .asyncMap(buildNoteEntities);
  }

  Stream<List<NoteImageEntity>> getNoteImageEntities(int year, String? userId) {
    return (db.select(
          db.notes,
        )..where(
          (n) =>
              n.deletedAt.isNull() &
              n.createdAt.year.equals(year) &
              (userId == null ? n.userId.isNull() : n.userId.equals(userId)),
        ))
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
    String? userId,
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
            (db.notes.content.isNotNull() & db.notes.content.equals('').not()) &
                (userId == null
                    ? db.notes.userId.isNull()
                    : db.notes.userId.equals(userId)));
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
                  db.noteTags.linkedTagId.isNull() &
                  db.noteTags.deletedAt.isNull(),
            ),
          ])
          ..where(exp)
          ..orderBy([OrderingTerm.asc(db.notes.createdAt.datetime)]))
        .watch()
        .asyncMap(buildNoteEntities);
  }

  Future<Jiffy?> getStartDate({String? userId}) async {
    final row =
        await (db.select(
                db.notes,
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt.datetime)])
              ..where(
                (t) => userId == null
                    ? t.userId.isNull()
                    : t.userId.equals(userId),
              )
              ..limit(1))
            .getSingleOrNull();
    return row?.createdAt;
  }

  Future<void> deleteNoteById(String noteId) async {
    await (db.update(db.notes)..where(
          (n) => n.id.equals(noteId) & n.deletedAt.isNull(),
        ))
        .write(NotesCompanion(deletedAt: Value(Jiffy.now())));
  }
}
