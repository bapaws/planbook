import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class NotesRepository {
  NotesRepository({
    required AppDatabase db,
    required DatabaseTagApi tagApi,
  }) : _dbNoteApi = DatabaseNoteApi(db: db, tagApi: tagApi);

  final DatabaseNoteApi _dbNoteApi;

  Future<String> create({
    required String title,
    String? content,
    List<String>? images,
    List<Tag>? tags,
    String? taskId,
  }) async {
    return _dbNoteApi.create(
      title: title,
      content: content,
      images: images,
      tags: tags,
      taskId: taskId,
    );
  }

  Future<void> update({
    required Note note,
    List<Tag>? tags,
  }) async {
    await _dbNoteApi.update(note: note, tags: tags);
  }

  Future<NoteEntity?> getNoteEntityById(String noteId) async {
    return _dbNoteApi.getNoteEntityById(noteId);
  }

  Stream<List<NoteEntity>> getNoteEntitiesByTaskId(String taskId) {
    return _dbNoteApi.getNoteEntitiesByTaskId(taskId);
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
