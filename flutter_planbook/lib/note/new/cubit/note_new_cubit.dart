import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'note_new_state.dart';

class NoteNewCubit extends HydratedCubit<NoteNewState> {
  NoteNewCubit({
    required NotesRepository notesRepository,
    required AssetsRepository assetsRepository,
    NoteEntity? initialNote,
    TaskEntity? initialTask,
  }) : _notesRepository = notesRepository,
       _assetsRepository = assetsRepository,
       _initialTask = initialTask,
       _initialNote = initialNote,
       super(NoteNewState.fromData(note: initialNote, task: initialTask));

  final NotesRepository _notesRepository;
  final AssetsRepository _assetsRepository;
  final TaskEntity? _initialTask;
  final NoteEntity? _initialNote;

  @override
  String get id => _initialTask?.id ?? _initialNote?.id ?? '';

  @override
  NoteNewState? fromJson(Map<String, dynamic> json) {
    if (_initialTask != null) return null;
    if (_initialNote != null) return null;
    return NoteNewState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(NoteNewState state) {
    if (_initialTask != null) return null;
    if (_initialNote != null) return null;
    return state.toJson();
  }

  void onCreatedAtChanged(Jiffy createdAt) {
    emit(state.copyWith(createdAt: createdAt));
  }

  void onTitleChanged(String title) {
    emit(state.copyWith(title: title.trim()));
  }

  void onContentChanged(String content) {
    emit(state.copyWith(content: content.trim()));
  }

  Future<void> addImages(List<String> imagePaths) async {
    emit(state.copyWith(images: [...state.images, ...imagePaths]));
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

    if (state.initialNote != null) {
      final images = <String>[];
      if (state.images.isNotEmpty) {
        // 上传新的图片
        for (final image in state.images) {
          if (state.initialNote!.images.contains(image)) {
            images.add(image);
            continue;
          }
          final url = await _assetsRepository.uploadImage(
            image,
            ResBucket.noteImages,
          );
          images.add(url);
        }
        // 删除不在新 images 中的图片
        final removedImages = <String>[];
        for (final image in state.initialNote!.images) {
          if (!images.contains(image)) {
            removedImages.add(image);
          }
        }
        if (removedImages.isNotEmpty) {
          await _assetsRepository.removeImages(
            removedImages,
            ResBucket.noteImages,
          );
        }
      }
      // 编辑模式：更新现有的 note
      final updatedNote = Note(
        id: state.initialNote!.id,
        title: state.title,
        content: state.content.isEmpty ? null : state.content,
        images: images,
        taskId: state.task?.id,
        createdAt: state.createdAt ?? state.initialNote!.createdAt,
        updatedAt: Jiffy.now(),
        deletedAt: state.initialNote!.deletedAt,
      );
      await _notesRepository.update(
        note: updatedNote,
        tags: state.tags.isEmpty ? null : state.tags,
      );
    } else {
      // 上传新的图片
      final images = <String>[];
      if (state.images.isNotEmpty) {
        for (final image in state.images) {
          final url = await _assetsRepository.uploadImage(
            image,
            ResBucket.noteImages,
          );
          images.add(url);
        }
      }

      // 新建模式：创建新的 note
      await _notesRepository.create(
        title: state.title,
        content: state.content.isEmpty ? null : state.content,
        images: images.isEmpty ? null : images,
        tags: state.tags.isEmpty ? null : state.tags,
        taskId: state.task?.id,
        createdAt: state.createdAt,
      );
      await clear();
    }
    emit(const NoteNewState(status: PageStatus.success));
  }

  Future<void> onDelete() async {
    emit(state.copyWith(status: PageStatus.loading));
    await _notesRepository.deleteNoteById(state.initialNote!.id);
    emit(const NoteNewState(status: PageStatus.dispose));
  }
}
