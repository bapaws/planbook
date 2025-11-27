import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'tag_picker_event.dart';
part 'tag_picker_state.dart';

enum TagPickerMode { multiSelect, singleSelect }

class TagPickerBloc extends Bloc<TagPickerEvent, TagPickerState> {
  TagPickerBloc({
    required TagsRepository tagsRepository,
    this.mode = TagPickerMode.multiSelect,
  }) : _tagsRepository = tagsRepository,
       super(const TagPickerState()) {
    on<TagPickerRequested>(_onRequested);
    on<TagPickerSelected>(_onSelected);
    on<TagPickerMultiSelected>(_onMultiSelected);
    on<TagPickerSelectedAll>(_onSelectedAll);
    on<TagPickerUnselectedAll>(_onUnselectedAll);
    on<TagPickerDeleted>(_onDeleted);
  }

  final TagsRepository _tagsRepository;

  final TagPickerMode mode;

  Future<void> _onRequested(
    TagPickerRequested event,
    Emitter<TagPickerState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _tagsRepository.getAllTags(),
      onData: (tags) {
        return state.copyWith(status: PageStatus.success, tags: tags);
      },
    );
  }

  Future<void> _onSelected(
    TagPickerSelected event,
    Emitter<TagPickerState> emit,
  ) async {
    final selectedTagIds = [...state.selectedTagIds];
    final tagIndex = state.tags.indexWhere((tag) => tag.id == event.tag.id);
    if (tagIndex == -1) return;

    if (selectedTagIds.contains(event.tag.id)) {
      selectedTagIds.remove(event.tag.id);

      // var parentId = event.tag.parentId;
      // for (var i = tagIndex - 1; i >= 0; i--) {
      //   final tag = state.tags[i];
      //   if (tag.id == parentId) {
      //     selectedTagIds.remove(tag.id);
      //     parentId = tag.parentId;
      //   }
      //   if (parentId == null) break;
      // }
    } else {
      if (mode == TagPickerMode.singleSelect && selectedTagIds.isNotEmpty) {
        selectedTagIds.remove(state.selectedTagIds.first);
      }
      selectedTagIds.add(event.tag.id);

      // 如果选中的是子标签，自动选中父标签
      // var parentId = event.tag.parentId;
      // for (var i = tagIndex - 1; i >= 0; i--) {
      //   final tag = state.tags[i];
      //   if (tag.id == parentId) {
      //     selectedTagIds.add(tag.id);
      //     parentId = tag.parentId;
      //   }
      //   if (parentId == null) break;
      // }
    }
    emit(state.copyWith(selectedTagIds: selectedTagIds));
  }

  Future<void> _onMultiSelected(
    TagPickerMultiSelected event,
    Emitter<TagPickerState> emit,
  ) async {
    if (state.status == PageStatus.loading) {
      await stream.firstWhere((state) => state.status == PageStatus.success);
    }

    final selectedTagIds = [...state.selectedTagIds];
    for (final tag in event.tags) {
      final tagEntity = state.tags.firstWhereOrNull((t) => t.id == tag.id);
      if (tagEntity != null && !selectedTagIds.contains(tagEntity.id)) {
        selectedTagIds.add(tagEntity.id);

        // 如果选中的是子标签，自动选中父标签
        if (tagEntity.parentId != null) {
          final parentTag = state.tags.firstWhereOrNull(
            (t) => t.id == tagEntity.parentId,
          );
          if (parentTag != null && !selectedTagIds.contains(parentTag.id)) {
            selectedTagIds.add(parentTag.id);
          }
        }
      }
    }
    emit(state.copyWith(selectedTagIds: selectedTagIds));
  }

  Future<void> _onSelectedAll(
    TagPickerSelectedAll event,
    Emitter<TagPickerState> emit,
  ) async {
    final selectedTagIds = [...state.selectedTagIds];
    for (final tag in state.tags) {
      if (!selectedTagIds.contains(tag.id)) {
        selectedTagIds.add(tag.id);
      }
    }
    emit(state.copyWith(selectedTagIds: selectedTagIds));
  }

  Future<void> _onUnselectedAll(
    TagPickerUnselectedAll event,
    Emitter<TagPickerState> emit,
  ) async {
    emit(state.copyWith(selectedTagIds: []));
  }

  Future<void> _onDeleted(
    TagPickerDeleted event,
    Emitter<TagPickerState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _tagsRepository.deleteTag(event.tag.id);
    emit(state.copyWith(status: PageStatus.success));
  }
}
