import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'journal_timeline_event.dart';
part 'journal_timeline_state.dart';

class JournalTimelineBloc
    extends Bloc<JournalTimelineEvent, JournalTimelineState> {
  JournalTimelineBloc({required TasksRepository tasksRepository})
    : _tasksRepository = tasksRepository,
      super(const JournalTimelineState()) {
    on<JournalTimelineRequested>(_onRequested);
    on<JournalTimelineTaskCountRequested>(_onTaskCountRequested);
  }

  final TasksRepository _tasksRepository;

  Future<void> _onRequested(
    JournalTimelineRequested event,
    Emitter<JournalTimelineState> emit,
  ) async {
    final stream = _tasksRepository.getCompletedTaskEntities(date: event.date);
    await emit.forEach(
      stream,
      onData: (tasks) {
        final startOfDay = event.date.toLocal().startOf(Unit.day);
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
          morningTasks: morningTasks,
          afternoonTasks: afternoonTasks,
          eveningTasks: eveningTasks,
        );
      },
    );
  }

  Future<void> _onTaskCountRequested(
    JournalTimelineTaskCountRequested event,
    Emitter<JournalTimelineState> emit,
  ) async {
    final stream = _tasksRepository.getTaskCount(
      mode: TaskListMode.today,
      date: event.date,
    );
    await emit.forEach(
      stream,
      onData: (count) {
        return state.copyWith(taskCount: count);
      },
    );
  }
}
