part of 'task_picker_bloc.dart';

final class TaskPickerState extends Equatable {
  const TaskPickerState({
    this.status = PageStatus.initial,
    this.inboxTasks = const [],
    this.todayTasks = const [],
  });

  final PageStatus status;
  final List<TaskEntity> inboxTasks;
  final List<TaskEntity> todayTasks;

  @override
  List<Object?> get props => [status, inboxTasks, todayTasks];

  TaskPickerState copyWith({
    PageStatus? status,
    List<TaskEntity>? inboxTasks,
    List<TaskEntity>? todayTasks,
  }) {
    return TaskPickerState(
      status: status ?? this.status,
      inboxTasks: inboxTasks ?? this.inboxTasks,
      todayTasks: todayTasks ?? this.todayTasks,
    );
  }
}
