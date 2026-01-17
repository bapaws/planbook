part of 'discover_focus_bloc.dart';

final class DiscoverFocusState extends Equatable {
  const DiscoverFocusState({
    required this.date,
    this.mindMap,
    this.status = PageStatus.initial,
    this.isExpandedAllNodes = false,
    this.selectedYearlyNode,
    this.selectedMonthlyNode,
    this.selectedWeeklyNode,
    this.selectedDailyNode,
  });

  final PageStatus status;

  final Jiffy date;

  final NoteMindMapEntity? mindMap;

  final bool isExpandedAllNodes;

  final NoteMindMapEntity? selectedYearlyNode;
  final NoteMindMapEntity? selectedMonthlyNode;
  final NoteMindMapEntity? selectedWeeklyNode;
  final NoteMindMapEntity? selectedDailyNode;

  @override
  List<Object?> get props => [
    status,
    date,
    mindMap,
    isExpandedAllNodes,
    selectedYearlyNode,
    selectedMonthlyNode,
    selectedWeeklyNode,
    selectedDailyNode,
  ];

  DiscoverFocusState copyWith({
    PageStatus? status,
    Jiffy? date,
    NoteMindMapEntity? mindMap,
    bool? isExpandedAllNodes,
    NoteMindMapEntity? selectedYearlyNode,
    NoteMindMapEntity? selectedMonthlyNode,
    NoteMindMapEntity? selectedWeeklyNode,
    NoteMindMapEntity? selectedDailyNode,
  }) {
    return DiscoverFocusState(
      status: status ?? this.status,
      date: date ?? this.date,
      mindMap: mindMap ?? this.mindMap,
      isExpandedAllNodes: isExpandedAllNodes ?? this.isExpandedAllNodes,
      selectedYearlyNode: selectedYearlyNode ?? this.selectedYearlyNode,
      selectedMonthlyNode: selectedMonthlyNode ?? this.selectedMonthlyNode,
      selectedWeeklyNode: selectedWeeklyNode ?? this.selectedWeeklyNode,
      selectedDailyNode: selectedDailyNode ?? this.selectedDailyNode,
    );
  }
}
