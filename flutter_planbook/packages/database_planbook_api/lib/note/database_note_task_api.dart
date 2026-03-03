import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class DatabaseNoteTaskApi {
  DatabaseNoteTaskApi({
    required this.db,
  });

  final AppDatabase db;

  Future<List<Note>> generateNoteContentByTaskActivities(
    List<TaskActivity> activities,
  ) async {
    final result = <Note>[];
    for (final activity in activities) {
      final taskId = activity.taskId;
      if (taskId == null) continue;

      final task = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(taskId))).getSingleOrNull();
      if (task == null) continue;

      final date = activity.occurrenceAt ?? activity.startAt ?? activity.endAt;
      final notes =
          await (db.select(db.notes)..where((t) {
                var exp =
                    (t.content.like('%✅ ${task.title}%') |
                        t.content.like('%❌ ${task.title}%')) &
                    t.deletedAt.isNull() &
                    t.focusAt.isNotNull();
                if (date != null) {
                  exp &=
                      ((t.type.equals(NoteType.dailyFocus.name) |
                              t.type.equals(NoteType.dailySummary.name)) &
                          t.focusAt.equals(
                            NoteType.dailyFocus
                                .normalizedFocusAt(date)
                                .dateTime,
                          )) |
                      ((t.type.equals(NoteType.weeklyFocus.name) |
                              t.type.equals(NoteType.weeklySummary.name)) &
                          t.focusAt.equals(
                            NoteType.weeklyFocus
                                .normalizedFocusAt(date)
                                .dateTime,
                          )) |
                      ((t.type.equals(NoteType.monthlyFocus.name) |
                              t.type.equals(NoteType.monthlySummary.name)) &
                          t.focusAt.equals(
                            NoteType.monthlyFocus
                                .normalizedFocusAt(date)
                                .dateTime,
                          )) |
                      ((t.type.equals(NoteType.yearlyFocus.name) |
                              t.type.equals(NoteType.yearlySummary.name)) &
                          t.focusAt.equals(
                            NoteType.yearlyFocus
                                .normalizedFocusAt(date)
                                .dateTime,
                          ));
                }
                return exp;
              }))
              .get();
      if (notes.isEmpty) continue;
      for (final note in notes) {
        final completedTaskContent = '✅ ${task.title}';
        final uncompletedTaskContent = '❌ ${task.title}';

        final newTaskContent =
            activity.completedAt != null && activity.deletedAt == null
            ? completedTaskContent
            : uncompletedTaskContent;
        final newNoteContent = note.content
            ?.replaceAll(completedTaskContent, newTaskContent)
            .replaceAll(uncompletedTaskContent, newTaskContent);
        result.add(
          note.copyWith(
            content: Value(newNoteContent),
            updatedAt: Value(Jiffy.now()),
          ),
        );
      }
    }
    return result;
  }

  Future<void> updateTypeNoteContent(
    List<Note> notes,
  ) async {
    for (final note in notes) {
      await (db.update(
        db.notes,
      )..where((t) => t.id.equals(note.id))).write(note.toCompanion(false));
    }
  }
}
