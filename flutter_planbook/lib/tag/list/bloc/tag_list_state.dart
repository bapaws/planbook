part of 'tag_list_bloc.dart';

final class TagListState extends Equatable {
  const TagListState({
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

  TagListState copyWith({
    PageStatus? status,
    List<TagEntity>? tags,
    Set<String>? selectedTagIds,
  }) {
    return TagListState(
      status: status ?? this.status,
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
    );
  }
}
