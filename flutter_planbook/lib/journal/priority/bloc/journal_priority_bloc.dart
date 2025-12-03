import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'journal_priority_event.dart';
part 'journal_priority_state.dart';

class JournalPriorityBloc
    extends Bloc<JournalPriorityEvent, JournalPriorityState> {
  JournalPriorityBloc({
    required TasksRepository tasksRepository,
  }) : _tasksRepository = tasksRepository,
       super(const JournalPriorityState()) {
    on<JournalPriorityRequested>(
      _onJournalPriorityRequested,
      transformer: concurrent(),
    );
  }

  final TasksRepository _tasksRepository;

  Future<void> _onJournalPriorityRequested(
    JournalPriorityRequested event,
    Emitter<JournalPriorityState> emit,
  ) async {
    final date = event.date;
    emit(state.copyWith(status: PageStatus.loading));
    final stream = _tasksRepository.getCompletedTaskEntities(
      date: date,
      priority: event.priority,
    );
    await emit.forEach(
      stream,
      onData: (tasks) => state.copyWith(
        status: PageStatus.success,
        tasks: {...state.tasks, event.priority: tasks.take(10).toList()},
      ),
    );
  }
}
