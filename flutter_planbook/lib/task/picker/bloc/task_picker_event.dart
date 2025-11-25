part of 'task_picker_bloc.dart';

sealed class TaskPickerEvent extends Equatable {
  const TaskPickerEvent();

  @override
  List<Object> get props => [];
}

final class TaskPickerInboxRequested extends TaskPickerEvent {
  const TaskPickerInboxRequested();

  @override
  List<Object> get props => [];
}

final class TaskPickerTodayRequested extends TaskPickerEvent {
  const TaskPickerTodayRequested();

  @override
  List<Object> get props => [];
}
