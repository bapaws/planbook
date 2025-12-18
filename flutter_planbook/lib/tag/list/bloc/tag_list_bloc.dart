import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'tag_list_event.dart';
part 'tag_list_state.dart';

enum TagListMode {
  list,
  multiSelect,
  singleSelect;

  bool get isSelectable =>
      this == TagListMode.multiSelect || this == TagListMode.singleSelect;
}

class TagListBloc extends Bloc<TagListEvent, TagListState> {
  TagListBloc({
    required TagsRepository tagsRepository,
    this.mode = TagListMode.list,
    this.notIncludeTagIds = const {},
  }) : _tagsRepository = tagsRepository,
       super(const TagListState()) {
    on<TagListRequested>(_onRequested);
    on<TagListSelected>(_onSelected);
    on<TagListMultiSelected>(_onMultiSelected);
    on<TagListSelectedAll>(_onSelectedAll);
    on<TagListUnselectedAll>(_onUnselectedAll);
    on<TagListDeleted>(_onDeleted);
  }

  final TagsRepository _tagsRepository;

  final TagListMode mode;
  final Set<String> notIncludeTagIds;

  Future<void> _onRequested(
    TagListRequested event,
    Emitter<TagListState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _tagsRepository.getAllTags(notIncludeTagIds: notIncludeTagIds),
      onData: (tags) {
        return state.copyWith(
          status: PageStatus.success,
          tags: tags,
          selectedTagIds: (event.selectAll ?? false)
              ? tags.map((tag) => tag.id).toList()
              : [],
        );
      },
    );
  }

  Future<void> _onSelected(
    TagListSelected event,
    Emitter<TagListState> emit,
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
      if (mode == TagListMode.singleSelect && selectedTagIds.isNotEmpty) {
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
    TagListMultiSelected event,
    Emitter<TagListState> emit,
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
        // if (tagEntity.parentId != null) {
        //   final parentTag = state.tags.firstWhereOrNull(
        //     (t) => t.id == tagEntity.parentId,
        //   );
        //   if (parentTag != null && !selectedTagIds.contains(parentTag.id)) {
        //     selectedTagIds.add(parentTag.id);
        //   }
        // }
      }
    }
    emit(state.copyWith(selectedTagIds: selectedTagIds));
  }

  Future<void> _onSelectedAll(
    TagListSelectedAll event,
    Emitter<TagListState> emit,
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
    TagListUnselectedAll event,
    Emitter<TagListState> emit,
  ) async {
    emit(state.copyWith(selectedTagIds: []));
  }

  Future<void> _onDeleted(
    TagListDeleted event,
    Emitter<TagListState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _tagsRepository.deleteById(event.tag.id);
    emit(state.copyWith(status: PageStatus.success));
  }
}
