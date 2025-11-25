part of 'tag_list_bloc.dart';

sealed class TagListEvent extends Equatable {
  const TagListEvent();

  @override
  List<Object?> get props => [];
}

final class TagListRequested extends TagListEvent {
  const TagListRequested({this.selectAll = false});

  final bool? selectAll;

  @override
  List<Object?> get props => [selectAll];
}

final class TagListSelected extends TagListEvent {
  const TagListSelected({required this.tag});

  final TagEntity tag;

  @override
  List<Object?> get props => [tag];
}

final class TagListMultiSelected extends TagListEvent {
  const TagListMultiSelected({required this.tags});

  final List<TagEntity> tags;

  @override
  List<Object?> get props => [tags];
}

final class TagListSelectedAll extends TagListEvent {
  const TagListSelectedAll();

  @override
  List<Object?> get props => [];
}

final class TagListUnselectedAll extends TagListEvent {
  const TagListUnselectedAll();

  @override
  List<Object?> get props => [];
}

final class TagListDeleted extends TagListEvent {
  const TagListDeleted({required this.tag});

  final TagEntity tag;

  @override
  List<Object?> get props => [tag];
}
