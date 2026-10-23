import 'dart:async';
import 'dart:convert';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

TaskEntity _task(String title) => TaskEntity(
  task: Task(
    id: title,
    title: title,
    layer: 0,
    childCount: 0,
    order: 0,
    isAllDay: true,
    alarms: const [],
    createdAt: Jiffy.parse('2026-10-19'),
  ),
);

class _AccountNotes extends NotesRepository {
  _AccountNotes({
    required super.sp,
    required super.db,
    required super.tagApi,
    required super.outboxApi,
  });
  String? account;
  @override
  String? get userId => account;
}

class _Queries extends QueryInterceptor {
  Future<void> Function()? afterPeriodRead;
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await executor.runSelect(statement, args);
    if (statement.contains('FROM "notes"') && statement.contains('LIMIT 1')) {
      final action = afterPeriodRead;
      afterPeriodRead = null;
      await action?.call();
    }
    return rows;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final date = Jiffy.parse('2026-10-19');
  late AppDatabase db;
  late OutboxApi outbox;
  late DatabaseTagApi tags;
  late _AccountNotes notes;
  late _AccountNotes other;
  late _Queries queries;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    queries = _Queries();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(queries));
    outbox = OutboxApi(db: db);
    tags = DatabaseTagApi(db: db, outboxApi: outbox);
    final sp = await SharedPreferences.getInstance();
    notes = _AccountNotes(sp: sp, db: db, tagApi: tags, outboxApi: outbox);
    other = _AccountNotes(sp: sp, db: db, tagApi: tags, outboxApi: outbox);
  });
  tearDown(() async {
    await db.close();
  });

  for (final type in [...NoteType.focusTypes, ...NoteType.summaryTypes]) {
    test('$type：旧周期快照不决定写入 ID，保留当前笔记图片、标签和任务关联', () async {
      final current = PeriodNoteTarget(date: date, type: type);
      final old = PeriodNoteTarget(date: date.subtract(years: 1), type: type);
      final oldNote = await notes.create(
        title: '旧周期',
        content: '旧内容',
        type: type,
        focusAt: old.focusAt,
      );
      final tag = Tag(
        id: 'work',
        name: '工作',
        order: 0,
        level: 0,
        createdAt: date,
      );
      await db.into(db.tags).insert(tag);
      final currentNote = await notes.create(
        title: '自定义$type标题',
        content: '当前内容',
        type: type,
        focusAt: current.focusAt,
        images: ['keep.png'],
        tags: [TagEntity(tag: tag)],
        taskId: 'associated-task',
      );
      final beforeLinks = await db.select(db.noteTags).get();
      await notes.appendTaskLineToNote(
        title: '标准$type标题',
        focusAt: current.focusAt,
        noteType: type,
        task: _task('新任务'),
        currentNote: oldNote,
      );
      final rows = await db.select(db.notes).get();
      expect(rows, hasLength(2));
      expect(
        rows.singleWhere((n) => n.id == oldNote.id).toJson(),
        oldNote.toJson(),
      );
      final updated = rows.singleWhere((n) => n.id == currentNote.id);
      expect(updated.content, '当前内容\n⭕️ 新任务');
      expect(updated.title, currentNote.title);
      final payload = (await db.select(db.syncOutbox).get())
          .lastWhere(
            (row) =>
                row.targetTable == 'notes' && row.recordId == currentNote.id,
          )
          .payload;
      expect(
        (jsonDecode(payload) as Map<String, dynamic>)['title'],
        currentNote.title,
      );
      expect(updated.images, ['keep.png']);
      expect(updated.taskId, 'associated-task');
      expect(
        (await db.select(db.noteTags).get()).map((link) => link.toJson()),
        beforeLinks.map((link) => link.toJson()),
      );
    });
  }

  test('首次拖入使用标准标题，旧快照追加保留其后显式保存的新标题', () async {
    final target = PeriodNoteTarget(date: date, type: NoteType.dailyFocus);
    await notes.appendTaskLineToNote(
      title: '标准标题',
      focusAt: target.focusAt,
      noteType: target.type,
      task: _task('首次任务'),
      currentNote: null,
    );
    final first = (await db.select(db.notes).get()).single;
    expect(first.title, '标准标题');
    final renamed = await other.savePeriodNote(
      target: target,
      title: '用户新标题',
      content: first.content!,
    );
    expect(renamed.id, first.id);
    expect(renamed.title, '用户新标题');
    await notes.appendTaskLineToNote(
      title: '标准标题',
      focusAt: target.focusAt,
      noteType: target.type,
      task: _task('追加任务'),
      currentNote: first,
    );
    final saved = (await db.select(db.notes).get()).single;
    expect(saved.id, first.id);
    expect(saved.title, '用户新标题');
    expect(saved.content, '⭕️ 首次任务\n⭕️ 追加任务');
  });

  test('已有空标题也保持为空，不因拖入任务被改名', () async {
    final target = PeriodNoteTarget(date: date, type: NoteType.monthlySummary);
    final first = await notes.savePeriodNote(
      target: target,
      title: '',
      content: '正文',
    );
    await notes.appendTaskLineToNote(
      title: '标准标题',
      focusAt: target.focusAt,
      noteType: target.type,
      task: _task('新任务'),
      currentNote: first,
    );
    final saved = (await db.select(db.notes).get()).single;
    expect(saved.title, isEmpty);
    expect(saved.content, '正文\n⭕️ 新任务');
  });

  for (final editorFirst in [true, false]) {
    test('自定义标题编辑与拖入交错，编辑先执行=$editorFirst，保留最新标题且不重复创建', () async {
      final target = PeriodNoteTarget(date: date, type: NoteType.weeklyFocus);
      final old = await notes.savePeriodNote(
        target: target,
        title: '原自定义标题',
        content: '原文',
      );
      final entered = Completer<void>();
      final resume = Completer<void>();
      queries.afterPeriodRead = () {
        entered.complete();
        return resume.future;
      };
      Future<void> save() async {
        await notes.savePeriodNote(
          target: target,
          title: '新自定义标题',
          content: '编辑正文',
        );
      }

      Future<void> append() => other.appendTaskLineToNote(
        title: '标准周标题',
        focusAt: target.focusAt,
        noteType: target.type,
        task: _task('交错任务'),
        currentNote: old,
      );
      final first = editorFirst ? save() : append();
      await entered.future;
      final second = editorFirst ? append() : save();
      resume.complete();
      await Future.wait([first, second]);
      final saved = (await db.select(db.notes).get()).single;
      expect(saved.id, old.id);
      expect(saved.title, '新自定义标题');
      expect(saved.content, editorFirst ? '编辑正文\n⭕️ 交错任务' : '编辑正文');
    });
  }

  test('两个仓库连续并发拖入只创建一份笔记，后写读取最新内容', () async {
    final target = PeriodNoteTarget(date: date, type: NoteType.monthlyFocus);
    await Future.wait([
      for (var i = 0; i < 12; i++)
        (i.isEven ? notes : other).appendTaskLineToNote(
          title: '当前月',
          focusAt: target.focusAt,
          noteType: target.type,
          task: _task('任务$i'),
          currentNote: null,
        ),
    ]);
    final rows = await db.select(db.notes).get();
    expect(rows, hasLength(1));
    expect(rows.single.content!.split('\n'), hasLength(12));
    for (var i = 0; i < 12; i++) {
      expect(rows.single.content, contains('⭕️ 任务$i'));
    }
    expect(rows.single.focusAt, target.focusAt);
  });

  test('空编辑器保存与拖入交错不重复创建，两个编辑器保存也只更新同一 ID', () async {
    final target = PeriodNoteTarget(date: date, type: NoteType.weeklyFocus);
    final saved = await notes.savePeriodNote(
      target: target,
      title: '本周',
      content: '编辑内容',
    );
    await other.appendTaskLineToNote(
      title: '本周',
      focusAt: target.focusAt,
      noteType: target.type,
      task: _task('后续任务'),
      currentNote: null,
    );
    expect((await db.select(db.notes).get()).single.content, '编辑内容\n⭕️ 后续任务');
    await Future.wait([
      notes.savePeriodNote(target: target, title: '本周', content: '编辑器一'),
      other.savePeriodNote(target: target, title: '本周', content: '编辑器二'),
    ]);
    final rows = await db.select(db.notes).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, saved.id);
    expect(rows.single.content, '编辑器二');
  });

  for (final editorFirst in [true, false]) {
    test('编辑保存先执行=$editorFirst：空结果读到后交错提交只创建一份当前周期笔记', () async {
      final target = PeriodNoteTarget(
        date: date,
        type: NoteType.monthlySummary,
      );
      final oldTarget = PeriodNoteTarget(
        date: date.subtract(months: 1),
        type: target.type,
      );
      final old = await notes.savePeriodNote(
        target: oldTarget,
        title: '旧月',
        content: '旧内容',
      );
      final entered = Completer<void>();
      final resume = Completer<void>();
      queries.afterPeriodRead = () {
        entered.complete();
        return resume.future;
      };
      Future<void> save() async {
        await notes.savePeriodNote(
          target: target,
          title: '本月',
          content: '编辑内容',
        );
      }

      Future<void> append() => other.appendTaskLineToNote(
        title: '本月',
        focusAt: target.focusAt,
        noteType: target.type,
        task: _task('交错拖入'),
        currentNote: null,
      );
      final first = editorFirst ? save() : append();
      await entered.future;
      final second = editorFirst ? append() : save();
      resume.complete();
      await Future.wait([first, second]);
      final rows = await db.select(db.notes).get();
      expect(rows, hasLength(2));
      expect(rows.singleWhere((n) => n.id == old.id).toJson(), old.toJson());
      final current = rows.singleWhere((n) => n.id != old.id);
      expect(target.accepts(current), isTrue);
      expect(current.content, editorFirst ? '编辑内容\n⭕️ 交错拖入' : '编辑内容');
      final inserts = (await db.select(db.syncOutbox).get()).where(
        (row) =>
            row.targetTable == 'notes' &&
            row.operation == 'insert' &&
            row.recordId == current.id,
      );
      expect(inserts, hasLength(1));
    });
  }

  test('相同任务连续拖入不重复追加未完成标记行', () async {
    final target = PeriodNoteTarget(date: date, type: NoteType.dailyFocus);
    await Future.wait([
      notes.appendTaskLineToNote(
        title: '今日',
        focusAt: target.focusAt,
        noteType: target.type,
        task: _task('同一任务'),
        currentNote: null,
      ),
      other.appendTaskLineToNote(
        title: '今日',
        focusAt: target.focusAt,
        noteType: target.type,
        task: _task('同一任务'),
        currentNote: null,
      ),
    ]);
    final rows = await db.select(db.notes).get();
    expect(rows, hasLength(1));
    expect(rows.single.content, '⭕️ 同一任务');
  });

  test('旧笔记被删除后写入新实例，不复活旧 ID 或覆盖其他周期', () async {
    final target = PeriodNoteTarget(date: date, type: NoteType.dailyFocus);
    final old = await notes.savePeriodNote(
      target: target,
      title: '已删除',
      content: '旧内容',
    );
    await notes.deleteNoteById(old.id);
    final next = await notes.savePeriodNote(
      target: target,
      title: '新笔记',
      content: '新内容',
    );
    expect(next.id, isNot(old.id));
    final rows = await db.select(db.notes).get();
    expect(rows.singleWhere((n) => n.id == old.id).deletedAt, isNotNull);
    expect(rows.where((n) => n.deletedAt == null), hasLength(1));
  });

  test('事务内读到目标后换号则整次写入回滚，不产生新笔记或 Outbox', () async {
    notes.account = 'a';
    final target = PeriodNoteTarget(date: date, type: NoteType.monthlySummary);
    queries.afterPeriodRead = () async {
      notes.account = 'b';
    };
    await expectLater(
      notes.savePeriodNote(target: target, title: '旧账号', content: '不能写入'),
      throwsStateError,
    );
    expect(await db.select(db.notes).get(), isEmpty);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
    final saved = await notes.savePeriodNote(
      target: target,
      title: '新账号',
      content: '允许写入',
    );
    expect(saved.userId, 'b');
  });

  for (final start in StartOfWeek.values) {
    test('周起始 $start：存储日期属于原查询周期，夏令时后仍可复用同一笔记', () async {
      final previous = Jiffy.now().startOfWeek;
      await Jiffy.setLocale('en', startOfWeek: start);
      addTearDown(() => Jiffy.setLocale('en', startOfWeek: previous));
      final target = PeriodNoteTarget(
        date: Jiffy.parse('2026-11-01'),
        type: NoteType.weeklyFocus,
      );
      expect(target.focusAt.dateTime.weekday, DateTime.monday);
      expect(target.focusAt.isBefore(target.start), isFalse);
      expect(target.focusAt.isAfter(target.end), isFalse);
      final first = await notes.savePeriodNote(
        target: target,
        title: '周笔记',
        content: '当前内容',
      );
      final second = await notes.savePeriodNote(
        target: PeriodNoteTarget(date: target.focusAt, type: target.type),
        title: '周笔记',
        content: '新内容',
      );
      expect(second.id, first.id);
      expect(
        (await notes.getNoteByFocusAt(target.start, type: target.type).first)!
            .toJson(),
        second.toJson(),
      );
    });
  }
}
