part of 'root_discover_bloc.dart';

final class RootDiscoverState extends Equatable {
  const RootDiscoverState({
    this.tab = RootDiscoverTab.journal,
    this.autoPlayFrom,
    this.autoPlayTo,
  });

  final RootDiscoverTab tab;

  final Jiffy? autoPlayFrom;
  final Jiffy? autoPlayTo;

  @override
  List<Object?> get props => [tab, autoPlayFrom, autoPlayTo];

  RootDiscoverState copyWith({
    RootDiscoverTab? tab,
    Jiffy? autoPlayFrom,
    Jiffy? autoPlayTo,
  }) {
    return RootDiscoverState(
      tab: tab ?? this.tab,
      autoPlayFrom: autoPlayFrom ?? this.autoPlayFrom,
      autoPlayTo: autoPlayTo ?? this.autoPlayTo,
    );
  }
}
