part of 'discover_focus_bloc.dart';

final class DiscoverFocusState extends Equatable {
  const DiscoverFocusState({
    required this.date,
    this.mindMap,
    this.flatNodes = const [],
    this.status = PageStatus.initial,
    this.isExpandedAllNodes = false,
    this.selectedYearlyNode,
    this.selectedMonthlyNode,
    this.selectedWeeklyNode,
    this.selectedDailyNode,
    this.isCalendarExpanded = false,
  });

  final PageStatus status;

  final Jiffy date;

  final NoteMindMapEntity? mindMap;
  final List<NoteMindMapEntity> flatNodes;

  final bool isExpandedAllNodes;

  final NoteMindMapEntity? selectedYearlyNode;
  final NoteMindMapEntity? selectedMonthlyNode;
  final NoteMindMapEntity? selectedWeeklyNode;
  final NoteMindMapEntity? selectedDailyNode;

  final bool isCalendarExpanded;

  @override
  List<Object?> get props => [
    status,
    date,
    mindMap,
    flatNodes,
    isExpandedAllNodes,
    selectedYearlyNode,
    selectedMonthlyNode,
    selectedWeeklyNode,
    selectedDailyNode,
    isCalendarExpanded,
  ];

  DiscoverFocusState copyWith({
    PageStatus? status,
    Jiffy? date,
    NoteMindMapEntity? mindMap,
    List<NoteMindMapEntity>? flatNodes,
    bool? isExpandedAllNodes,
    NoteMindMapEntity? selectedYearlyNode,
    NoteMindMapEntity? selectedMonthlyNode,
    NoteMindMapEntity? selectedWeeklyNode,
    NoteMindMapEntity? selectedDailyNode,
    bool? isCalendarExpanded,
  }) {
    return DiscoverFocusState(
      status: status ?? this.status,
      date: date ?? this.date,
      mindMap: mindMap ?? this.mindMap,
      flatNodes: flatNodes ?? this.flatNodes,
      isExpandedAllNodes: isExpandedAllNodes ?? this.isExpandedAllNodes,
      selectedYearlyNode: selectedYearlyNode ?? this.selectedYearlyNode,
      selectedMonthlyNode: selectedMonthlyNode ?? this.selectedMonthlyNode,
      selectedWeeklyNode: selectedWeeklyNode ?? this.selectedWeeklyNode,
      selectedDailyNode: selectedDailyNode ?? this.selectedDailyNode,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
    );
  }
}
