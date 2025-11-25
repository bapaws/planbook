part of 'tag_picker_bloc.dart';

final class TagPickerState extends Equatable {
  const TagPickerState({
    this.status = PageStatus.initial,
    this.tags = const [],
    this.selectedTagIds = const {},
  });

  final List<TagEntity> tags;
  final PageStatus status;

  final Set<String> selectedTagIds;

  bool get isAllSelected => selectedTagIds.length == tags.length;

  @override
  List<Object?> get props => [status, tags, selectedTagIds];

  TagPickerState copyWith({
    PageStatus? status,
    List<TagEntity>? tags,
    Set<String>? selectedTagIds,
  }) {
    return TagPickerState(
      status: status ?? this.status,
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
    );
  }
}
