part of 'discover_journal_play_cubit.dart';

final class DiscoverJournalPlayState extends Equatable {
  const DiscoverJournalPlayState({
    required this.from,
    required this.to,
  });

  final Jiffy from;
  final Jiffy to;

  @override
  List<Object?> get props => [from, to];

  DiscoverJournalPlayState copyWith({
    Jiffy? from,
    Jiffy? to,
  }) {
    return DiscoverJournalPlayState(
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}
