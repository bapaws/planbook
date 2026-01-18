part of 'root_discover_bloc.dart';

sealed class RootDiscoverEvent extends Equatable {
  const RootDiscoverEvent();

  @override
  List<Object> get props => [];
}

final class RootDiscoverTabSelected extends RootDiscoverEvent {
  const RootDiscoverTabSelected({required this.tab});

  final RootDiscoverTab tab;

  @override
  List<Object> get props => [tab];
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
