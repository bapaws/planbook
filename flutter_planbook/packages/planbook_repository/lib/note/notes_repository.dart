import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class NotesRepository {
  NotesRepository({
    required AppDatabase db,
    required DatabaseTagApi tagApi,
  }) : _dbNoteApi = DatabaseNoteApi(db: db, tagApi: tagApi);

  final DatabaseNoteApi _dbNoteApi;

  Future<void> create({
    required String title,
    String? content,
    List<String>? images,
    List<Tag>? tags,
  }) async {
    await _dbNoteApi.create(
      title: title,
      content: content,
      images: images,
      tags: tags,
    );
  }

  Future<void> update({
    required Note note,
    List<Tag>? tags,
  }) async {
    await _dbNoteApi.update(note: note, tags: tags);
  }

  Future<Note?> getNoteById(String noteId) async {
    return _dbNoteApi.getNoteById(noteId);
  }

  Stream<List<Note>> getNotesByTaskId(String taskId) {
    return _dbNoteApi.getNotesByTaskId(taskId);
  }

  Stream<List<NoteEntity>> getNoteEntitiesByDate(
    Jiffy date, {
    List<String>? tagIds,
  }) {
    return _dbNoteApi.getNoteEntitiesByDate(date, tagIds: tagIds);
  }

  Stream<List<NoteImageEntity>> getNoteImageEntities({
    int limit = 20,
    int offset = 0,
  }) {
    return _dbNoteApi.getNoteImageEntities(limit: limit, offset: offset);
  }
}
