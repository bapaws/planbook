part of 'discover_cover_bloc.dart';

sealed class DiscoverCoverEvent extends Equatable {
  const DiscoverCoverEvent();

  @override
  List<Object?> get props => [];
}

final class DiscoverCoverRequested extends DiscoverCoverEvent {
  const DiscoverCoverRequested();
}

final class DiscoverCoverColorSchemeRequested extends DiscoverCoverEvent {
  const DiscoverCoverColorSchemeRequested({required this.coverPath});

  final String coverPath;

  @override
  List<Object?> get props => [coverPath];
}

final class DiscoverCoverSelected extends DiscoverCoverEvent {
  const DiscoverCoverSelected({required this.coverPath});

  final String coverPath;

  @override
  List<Object?> get props => [coverPath];
}
