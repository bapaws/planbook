part of 'diary_notebook_bloc.dart';

sealed class DiaryNotebookEvent extends Equatable {
  const DiaryNotebookEvent();

  @override
  List<Object?> get props => [];
}

final class DiaryNotebookStarted extends DiaryNotebookEvent {
  const DiaryNotebookStarted();
}

final class DiaryNotebookSaved extends DiaryNotebookEvent {
  const DiaryNotebookSaved({required this.year, required this.look});

  final int year;
  final DiaryNotebookLook look;

  @override
  List<Object?> get props => [year, look];
}

final class DiaryNotebookYearChanged extends DiaryNotebookEvent {
  const DiaryNotebookYearChanged(this.year);

  final int year;

  @override
  List<Object?> get props => [year];
}

final class DiaryNotebookCalendarToggled extends DiaryNotebookEvent {
  const DiaryNotebookCalendarToggled({this.isExpanded});

  final bool? isExpanded;

  @override
  List<Object?> get props => [isExpanded];
}
