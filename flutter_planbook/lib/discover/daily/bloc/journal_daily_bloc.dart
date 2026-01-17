import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'journal_daily_event.dart';
part 'journal_daily_state.dart';

class JournalDailyBloc extends Bloc<JournalDailyEvent, JournalDailyState> {
  JournalDailyBloc({
    required this.date,
    required NotesRepository notesRepository,
    required TasksRepository tasksRepository,
  }) : _notesRepository = notesRepository,
       _tasksRepository = tasksRepository,
       super(const JournalDailyState()) {
    on<JournalDailyRequested>(_onRequested);
    on<JournalDailyPlannedTasksRequested>(_onPlannedTasksRequested);
    on<JournalDailyTasksRequested>(_onTasksRequested);
    on<JournalDailyNotesRequested>(_onNotesRequested);

    on<JournalDailyNoteTypeRequested>(
      _onNoteTypeRequested,
      transformer: concurrent(),
    );
  }

  final Jiffy date;

  final NotesRepository _notesRepository;
  final TasksRepository _tasksRepository;

  Future<void> _onRequested(
    JournalDailyRequested event,
    Emitter<JournalDailyState> emit,
  ) async {
    add(const JournalDailyPlannedTasksRequested());
    // add(const JournalDailyTasksRequested());
    add(const JournalDailyNotesRequested());
    add(
      const JournalDailyNoteTypeRequested(
        noteType: NoteType.dailyFocus,
      ),
    );
    add(
      const JournalDailyNoteTypeRequested(
        noteType: NoteType.dailySummary,
      ),
    );
  }

  Future<void> _onPlannedTasksRequested(
    JournalDailyPlannedTasksRequested event,
    Emitter<JournalDailyState> emit,
  ) async {
    final plannedTasksCount = _tasksRepository.getTaskCount(
      mode: TaskListMode.today,
      date: date,
    );
    final uncompletedTasksCount = _tasksRepository.getTaskCount(
      mode: TaskListMode.today,
      date: date,
      isCompleted: false,
    );
    final completedTasksCount = _tasksRepository.getCompletedTaskCount(
      date: date,
    );

    await emit.forEach(
      CombineLatestStream.list<int>([
        plannedTasksCount,
        uncompletedTasksCount,
        completedTasksCount,
        for (final priority in TaskPriority.values.reversed)
          _tasksRepository.getCompletedTaskCount(
            date: date,
            priority: priority,
          ),
      ]),
      onData: (counts) => state.copyWith(
        plannedTasksCount: counts[0],
        uncompletedTasksCount: counts[1],
        completedTasksCount: counts[2],
        completedInboxTasksCount: counts[2] - (counts[0] - counts[1]),
        completedTaskPriorityCounts: Map.fromEntries(
          TaskPriority.values.reversed.map(
            (priority) => MapEntry(
              priority,
              counts[3 + priority.index],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTasksRequested(
    JournalDailyTasksRequested event,
    Emitter<JournalDailyState> emit,
  ) async {
    await emit.forEach(
      _tasksRepository.getCompletedTaskEntities(date: date),
      onData: (tasks) {
        final counts = <TaskPriority, int>{};
        for (final task in tasks) {
          final priority = task.task.priority ?? TaskPriority.none;
          counts[priority] = (counts[priority] ?? 0) + 1;
        }
        final startOfDay = date.toLocal().startOf(Unit.day);
        final morningTasks = <TaskEntity>[];
        final afternoonTasks = <TaskEntity>[];
        final eveningTasks = <TaskEntity>[];
        for (final task in tasks) {
          final completedAt = task.completedAt;
          if (completedAt == null) continue;
          if (completedAt.isBefore(startOfDay.add(hours: 12))) {
            morningTasks.add(task);
          } else if (completedAt.isBefore(startOfDay.add(hours: 18))) {
            afternoonTasks.add(task);
          } else {
            eveningTasks.add(task);
          }
        }
        return state.copyWith(
          tasks: tasks,
          morningTasks: morningTasks,
          afternoonTasks: afternoonTasks,
          eveningTasks: eveningTasks,
          taskPriorityCounts: counts.entries
              .map(
                (e) => JournalDailyTaskPriorityCount(
                  priority: e.key,
                  totalCount: e.value,
                  completedCount: e.value,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _onNotesRequested(
    JournalDailyNotesRequested event,
    Emitter<JournalDailyState> emit,
  ) async {
    await emit.forEach(
      _notesRepository.getNoteEntitiesByDate(
        date,
        modes: [
          NoteListMode.written,
          NoteListMode.task,
        ],
      ),
      onData: (notes) {
        final startOfDay = date.toLocal().startOf(Unit.day);
        final writtenNotes = <NoteEntity>[];

        final morningTaskNotes = <NoteEntity>[];
        final afternoonTaskNotes = <NoteEntity>[];
        final eveningTaskNotes = <NoteEntity>[];
        for (final note in notes) {
          if (note.task != null) {
            if (note.createdAt.isBefore(startOfDay.add(hours: 12))) {
              morningTaskNotes.add(note);
            } else if (note.createdAt.isBefore(startOfDay.add(hours: 18))) {
              afternoonTaskNotes.add(note);
            } else {
              eveningTaskNotes.add(note);
            }
          } else {
            writtenNotes.add(note);
          }
        }
        return state.copyWith(
          morningTaskNotes: morningTaskNotes,
          afternoonTaskNotes: afternoonTaskNotes,
          eveningTaskNotes: eveningTaskNotes,
          writtenNotes: writtenNotes,
        );
      },
    );
  }

  Future<void> _onNoteTypeRequested(
    JournalDailyNoteTypeRequested event,
    Emitter<JournalDailyState> emit,
  ) async {
    await emit.forEach(
      _notesRepository.getNoteByFocusAt(date, type: event.noteType),
      onData: (note) => state.copyWith(
        focusNote: event.noteType.isFocus ? note : null,
        summaryNote: event.noteType.isSummary ? note : null,
      ),
    );
  }

  Future<void> _onTaskPriorityCountRequested(
    JournalDailyTaskPriorityCountRequested event,
    Emitter<JournalDailyState> emit,
  ) async {
    await emit.forEach(
      _tasksRepository.getTaskCount(
        date: date,
        mode: TaskListMode.today,
        priority: event.priority,
      ),
      onData: (note) => state.copyWith(
        taskPriorityCounts: [
          ...state.taskPriorityCounts,
          JournalDailyTaskPriorityCount(
            priority: event.priority,
            totalCount: note,
            completedCount: note,
          ),
        ],
      ),
    );
  }
}
