part of 'tag_picker_bloc.dart';

final class TagPickerState extends Equatable {
  const TagPickerState({
    this.status = PageStatus.initial,
    this.tags = const [],
    this.selectedTagIds = const [],
  });

  final List<TagEntity> tags;
  final PageStatus status;

  /// 选中的标签ID列表，保持顺序
  final List<String> selectedTagIds;

  bool get isAllSelected => selectedTagIds.length == tags.length;

  @override
  List<Object?> get props => [status, tags, selectedTagIds];

  TagPickerState copyWith({
    PageStatus? status,
    List<TagEntity>? tags,
    List<String>? selectedTagIds,
  }) {
    return TagPickerState(
      status: status ?? this.status,
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
    );
  }
}
