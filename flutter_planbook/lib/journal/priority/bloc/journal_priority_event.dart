part of 'journal_priority_bloc.dart';

sealed class JournalPriorityEvent extends Equatable {
  const JournalPriorityEvent();

  @override
  List<Object> get props => [];
}

final class JournalPriorityRequested extends JournalPriorityEvent {
  const JournalPriorityRequested({required this.date, required this.priority});

  final Jiffy date;
  final TaskPriority priority;

  @override
  List<Object> get props => [date, priority];
}
