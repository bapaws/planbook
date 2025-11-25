import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' as material;
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'tag_new_state.dart';

class TagNewCubit extends Cubit<TagNewState> {
  TagNewCubit({
    required TagsRepository tagsRepository,
    TagEntity? initialTag,
  }) : _tagsRepository = tagsRepository,
       super(TagNewState.fromData(tag: initialTag));

  final TagsRepository _tagsRepository;

  Future<void> onRequested() async {
    emit(state.copyWith(status: PageStatus.loading));

    if (state.light == null || state.dark == null) {
      final value = Random().nextInt(0xFFFFFFFF);
      final light = material.ColorScheme.fromSeed(
        seedColor: material.Color(value),
      );
      final dark = material.ColorScheme.fromSeed(
        seedColor: material.Color(value),
        brightness: material.Brightness.dark,
      );
      emit(
        state.copyWith(
          light: ColorScheme.fromColorScheme(
            light,
            argb: value,
          ),
          dark: ColorScheme.fromColorScheme(
            dark,
            argb: value,
          ),
        ),
      );
    }

    if (state.initialTag?.parentId != null) {
      final parentTag = await _tagsRepository.getTagEntityById(
        state.initialTag!.parentId!,
      );
      emit(state.copyWith(parentTag: parentTag));
    }
  }

  void onNameChanged(String name) {
    emit(state.copyWith(name: name));
  }

  void onColorSchemeChanged(ColorScheme light, ColorScheme dark) {
    emit(state.copyWith(light: light, dark: dark));
  }

  void onParentTagChanged(TagEntity? parentTag) {
    emit(state.copyWith(parentTag: parentTag));
  }

  Future<void> onSave() async {
    if (state.name.trim().isEmpty ||
        state.light == null ||
        state.dark == null) {
      emit(state.copyWith(status: PageStatus.failure));
      return;
    }

    emit(state.copyWith(status: PageStatus.loading));
    if (state.initialTag != null) {
      await _tagsRepository.updateTag(
        id: state.initialTag!.id,
        name: state.name,
        lightColorScheme: state.light,
        darkColorScheme: state.dark,
        parentTag: state.parentTag,
      );
    } else {
      await _tagsRepository.createTag(
        name: state.name,
        lightColorScheme: state.light!,
        darkColorScheme: state.dark!,
        parentTag: state.parentTag,
      );
    }
    emit(state.copyWith(status: PageStatus.success));
  }
}
