part of 'tag_picker_bloc.dart';

sealed class TagPickerEvent extends Equatable {
  const TagPickerEvent();

  @override
  List<Object> get props => [];
}

final class TagPickerRequested extends TagPickerEvent {
  const TagPickerRequested();

  @override
  List<Object> get props => [];
}

final class TagPickerSelected extends TagPickerEvent {
  const TagPickerSelected({required this.tag});

  final TagEntity tag;

  @override
  List<Object> get props => [tag];
}

final class TagPickerMultiSelected extends TagPickerEvent {
  const TagPickerMultiSelected({required this.tags});

  final List<TagEntity> tags;

  @override
  List<Object> get props => [tags];
}

final class TagPickerSelectedAll extends TagPickerEvent {
  const TagPickerSelectedAll();

  @override
  List<Object> get props => [];
}

final class TagPickerUnselectedAll extends TagPickerEvent {
  const TagPickerUnselectedAll();

  @override
  List<Object> get props => [];
}

final class TagPickerDeleted extends TagPickerEvent {
  const TagPickerDeleted({required this.tag});

  final TagEntity tag;

  @override
  List<Object> get props => [tag];
}
