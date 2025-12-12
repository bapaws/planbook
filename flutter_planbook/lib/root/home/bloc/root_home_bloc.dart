import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'root_home_event.dart';
part 'root_home_state.dart';

class RootHomeBloc extends Bloc<RootHomeEvent, RootHomeState> {
  RootHomeBloc({
    required TagsRepository tagsRepository,
  }) : _tagsRepository = tagsRepository,
       super(const RootHomeState()) {
    on<RootHomeRequested>(_onRequested);
    on<RootHomeTagSelected>(_onTagSelected);
    on<RootHomeTagSelectedAll>(_onTagSelectedAll);
    on<RootHomeTagUnselectedAll>(_onTagUnselectedAll);
    on<RootHomeTagDeleted>(_onTagDeleted);
    on<RootHomeDownloadJournalDayRequested>(_onDownloadJournalDayRequested);
  }

  final TagsRepository _tagsRepository;

  Future<void> _onRequested(
    RootHomeRequested event,
    Emitter<RootHomeState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _tagsRepository.getAllTags(),
      onData: (tags) {
        return state.copyWith(
          status: PageStatus.success,
          tags: tags,
          selectedTagIds: tags.map((tag) => tag.id).toSet(),
        );
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Error getting tags: $error');
        }
        return state.copyWith(status: PageStatus.failure);
      },
    );
  }

  Future<void> _onTagSelected(
    RootHomeTagSelected event,
    Emitter<RootHomeState> emit,
  ) async {
    final selectedTagIds = {...state.selectedTagIds};
    final tagIndex = state.tags.indexWhere((tag) => tag.id == event.tagId);
    if (tagIndex == -1) return;

    if (selectedTagIds.contains(event.tagId)) {
      selectedTagIds.remove(event.tagId);
    } else {
      selectedTagIds.add(event.tagId);
    }
    emit(state.copyWith(selectedTagIds: selectedTagIds));
  }

  Future<void> _onTagSelectedAll(
    RootHomeTagSelectedAll event,
    Emitter<RootHomeState> emit,
  ) async {
    final selectedTagIds = {...state.selectedTagIds};
    for (final tag in state.tags) {
      if (!selectedTagIds.contains(tag.id)) {
        selectedTagIds.add(tag.id);
      }
    }
    emit(state.copyWith(selectedTagIds: selectedTagIds));
  }

  Future<void> _onTagUnselectedAll(
    RootHomeTagUnselectedAll event,
    Emitter<RootHomeState> emit,
  ) async {
    emit(state.copyWith(selectedTagIds: {}));
  }

  Future<void> _onTagDeleted(
    RootHomeTagDeleted event,
    Emitter<RootHomeState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _tagsRepository.deleteById(event.tagId);
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _onDownloadJournalDayRequested(
    RootHomeDownloadJournalDayRequested event,
    Emitter<RootHomeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PageStatus.loading,
        downloadJournalDayCount: state.downloadJournalDayCount + 1,
      ),
    );
  }
}
