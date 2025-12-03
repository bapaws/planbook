part of 'root_home_bloc.dart';

final class RootHomeState extends Equatable {
  const RootHomeState({
    this.status = PageStatus.initial,
    this.todayTaskCount = 0,
    this.inboxTaskCount = 0,
    this.tags = const [],
    this.selectedTagIds = const {},
    this.downloadJournalDayCount = 0,
  });

  final PageStatus status;
  final int todayTaskCount;
  final int inboxTaskCount;

  final List<TagEntity> tags;
  final Set<String> selectedTagIds;

  final int downloadJournalDayCount;

  bool get isAllSelected => selectedTagIds.length == tags.length;

  List<TagEntity> get topLevelTags =>
      tags.where((tag) => tag.parentId == null).toList();

  @override
  List<Object> get props => [
    status,
    todayTaskCount,
    inboxTaskCount,
    tags,
    selectedTagIds,
    downloadJournalDayCount,
  ];

  RootHomeState copyWith({
    PageStatus? status,
    int? todayTaskCount,
    int? inboxTaskCount,
    List<TagEntity>? tags,
    Set<String>? selectedTagIds,
    int? downloadJournalDayCount,
  }) {
    return RootHomeState(
      status: status ?? this.status,
      todayTaskCount: todayTaskCount ?? this.todayTaskCount,
      inboxTaskCount: inboxTaskCount ?? this.inboxTaskCount,
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      downloadJournalDayCount:
          downloadJournalDayCount ?? this.downloadJournalDayCount,
    );
  }
}
