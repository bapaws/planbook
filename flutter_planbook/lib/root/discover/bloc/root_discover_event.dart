part of 'root_discover_bloc.dart';

sealed class RootDiscoverEvent extends Equatable {
  const RootDiscoverEvent();

  @override
  List<Object?> get props => [];
}

final class RootDiscoverAutoPlayRangeChanged extends RootDiscoverEvent {
  const RootDiscoverAutoPlayRangeChanged({
    required this.from,
    required this.to,
  });

  final Jiffy from;
  final Jiffy to;

  @override
  List<Object> get props => [from, to];
}

final class RootDiscoverFocusDateChanged extends RootDiscoverEvent {
  const RootDiscoverFocusDateChanged({required this.date, required this.type});

  final Jiffy? date;
  final NoteType? type;

  @override
  List<Object?> get props => [date, type];
}

final class RootDiscoverSummaryDateChanged extends RootDiscoverEvent {
  const RootDiscoverSummaryDateChanged({
    required this.date,
    required this.type,
  });

  final Jiffy? date;
  final NoteType? type;

  @override
  List<Object?> get props => [date, type];
}
