part of 'search_bloc.dart';

final class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.status = PageStatus.initial,
    this.tasks = const [],
    this.notes = const [],
    this.tags = const [],
  });

  final String query;
  final PageStatus status;
  final List<TaskEntity> tasks;
  final List<NoteEntity> notes;
  final List<TagEntity> tags;

  bool get hasResults =>
      tasks.isNotEmpty || notes.isNotEmpty || tags.isNotEmpty;

  @override
  List<Object?> get props => [query, status, tasks, notes, tags];

  SearchState copyWith({
    String? query,
    PageStatus? status,
    List<TaskEntity>? tasks,
    List<NoteEntity>? notes,
    List<TagEntity>? tags,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }
}
