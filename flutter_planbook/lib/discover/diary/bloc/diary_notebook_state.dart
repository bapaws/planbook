part of 'diary_notebook_bloc.dart';

final class DiaryNotebookState extends Equatable {
  const DiaryNotebookState({
    this.byYear = const {},
    this.year,
    this.isCalendarExpanded = false,
    this.saveFailureCount = 0,
  });

  /// 用户改过的年份。没改过的年份用 [lookFor] 里的预制外观。
  final Map<int, DiaryNotebookLook> byYear;

  /// 正在阅读的年份。空则用今年。
  final int? year;

  final bool isCalendarExpanded;

  /// 保存失败次数。增加时界面提示，成功不会改变它。
  final int saveFailureCount;

  int get selectedYear => year ?? DateTime.now().year;

  DiaryNotebookLook lookFor(int year) =>
      byYear[year] ?? DiaryNotebookLook.prefabFor(year);

  @override
  List<Object?> get props => [
    byYear,
    year,
    isCalendarExpanded,
    saveFailureCount,
  ];

  DiaryNotebookState copyWith({
    Map<int, DiaryNotebookLook>? byYear,
    int? year,
    bool? isCalendarExpanded,
    int? saveFailureCount,
  }) {
    return DiaryNotebookState(
      byYear: byYear ?? this.byYear,
      year: year ?? this.year,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
      saveFailureCount: saveFailureCount ?? this.saveFailureCount,
    );
  }
}
