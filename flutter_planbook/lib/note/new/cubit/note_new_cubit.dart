import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'note_new_state.dart';

class NoteNewCubit extends HydratedCubit<NoteNewState> {
  NoteNewCubit({
    required NotesRepository notesRepository,
    NoteEntity? initialNote,
  }) : _notesRepository = notesRepository,
       super(NoteNewState.fromData(note: initialNote));

  final NotesRepository _notesRepository;

  @override
  NoteNewState? fromJson(Map<String, dynamic> json) {
    return NoteNewState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(NoteNewState state) {
    return state.toJson();
  }

  void onTitleChanged(String title) {
    emit(state.copyWith(title: title));
  }

  void onContentChanged(String content) {
    emit(state.copyWith(content: content));
  }

  void addImages(List<String> imagePaths) {
    final currentImages = List<String>.from(state.images);
    currentImages.addAll(imagePaths);
    emit(state.copyWith(images: currentImages));
  }

  void removeImage(int index) {
    final currentImages = List<String>.from(state.images);
    if (index >= 0 && index < currentImages.length) {
      currentImages.removeAt(index);
      emit(state.copyWith(images: currentImages));
    }
  }

  void onTagsChanged(List<TagEntity> tags) {
    emit(state.copyWith(tags: tags));
  }

  void removeTag(int index) {
    final currentTags = List<TagEntity>.from(state.tags);
    if (index >= 0 && index < currentTags.length) {
      currentTags.removeAt(index);
      emit(state.copyWith(tags: currentTags));
    }
  }

  void onTaskSelected(TaskEntity task) {
    emit(state.copyWith(task: () => task.task));
  }

  void removeTask() {
    emit(state.copyWith(task: () => null));
  }

  Future<void> onSave() async {
    if (state.title.isEmpty) {
      emit(state.copyWith(status: PageStatus.failure));
      return;
    }

    emit(state.copyWith(status: PageStatus.loading));
    // 从 TagEntity 中提取 Tag 对象
    final tags = state.tags.map((tagEntity) => tagEntity.tag).toList();

    if (state.initialNote != null) {
      // 编辑模式：更新现有的 note
      final updatedNote = Note(
        id: state.initialNote!.id,
        title: state.title,
        content: state.content.isEmpty ? null : state.content,
        images: state.images,
        createdAt: state.initialNote!.createdAt,
        updatedAt: Jiffy.now(),
        deletedAt: state.initialNote!.deletedAt,
      );
      await _notesRepository.update(
        note: updatedNote,
        tags: tags.isEmpty ? null : tags,
      );
    } else {
      // 新建模式：创建新的 note
      await _notesRepository.create(
        title: state.title,
        content: state.content.isEmpty ? null : state.content,
        images: state.images.isEmpty ? null : state.images,
        tags: tags.isEmpty ? null : tags,
      );
      await clear();
    }
    emit(const NoteNewState(status: PageStatus.success));
  }
}
