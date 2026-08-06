import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'search_event.dart';
part 'search_state.dart';

EventTransformer<E> _debounceRestartable<E>(Duration duration) {
  return (events, mapper) =>
      events.debounceTime(duration).switchMap(mapper);
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required TagsRepository tagsRepository,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _tagsRepository = tagsRepository,
       super(const SearchState()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: _debounceRestartable(const Duration(milliseconds: 300)),
    );
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final TagsRepository _tagsRepository;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          query: query,
          status: PageStatus.initial,
          tasks: const [],
          notes: const [],
          tags: const [],
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        query: query,
        status: PageStatus.loading,
      ),
    );

    try {
      final results = await Future.wait([
        _tasksRepository.search(query),
        _notesRepository.search(query),
        _tagsRepository.search(query),
      ]);
      final tasks = results[0] as List<TaskEntity>;
      final notes = results[1] as List<NoteEntity>;
      final tags = results[2] as List<TagEntity>;
      emit(
        state.copyWith(
          query: query,
          status: PageStatus.success,
          tasks: tasks,
          notes: notes,
          tags: tags,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          query: query,
          status: PageStatus.failure,
          tasks: const [],
          notes: const [],
          tags: const [],
        ),
      );
    }
  }
}
