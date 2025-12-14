part of 'task_inbox_bloc.dart';

final class TaskInboxState extends Equatable {
  const TaskInboxState({this.count = 0});

  final int count;

  @override
  List<Object> get props => [count];

  TaskInboxState copyWith({int? count}) {
    return TaskInboxState(count: count ?? this.count);
  }
}
