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
