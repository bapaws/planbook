part of 'root_discover_bloc.dart';

final class RootDiscoverState extends Equatable {
  const RootDiscoverState({
    this.tab = RootDiscoverTab.journal,
  });

  final RootDiscoverTab tab;

  @override
  List<Object> get props => [tab];

  RootDiscoverState copyWith({
    RootDiscoverTab? tab,
  }) {
    return RootDiscoverState(
      tab: tab ?? this.tab,
    );
  }
}
