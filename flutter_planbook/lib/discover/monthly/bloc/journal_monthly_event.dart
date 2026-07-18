part of 'journal_monthly_bloc.dart';

sealed class JournalMonthlyEvent extends Equatable {
  const JournalMonthlyEvent();

  @override
  List<Object?> get props => [];
}

final class JournalMonthlyRequested extends JournalMonthlyEvent {
  const JournalMonthlyRequested({required this.month});

  final Jiffy month;

  @override
  List<Object?> get props => [month];
}
