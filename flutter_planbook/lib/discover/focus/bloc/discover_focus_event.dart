part of 'discover_focus_bloc.dart';

sealed class DiscoverFocusEvent extends Equatable {
  const DiscoverFocusEvent();

  @override
  List<Object> get props => [];
}

final class DiscoverFocusRequested extends DiscoverFocusEvent {
  const DiscoverFocusRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class DiscoverFocusNodeSelected extends DiscoverFocusEvent {
  const DiscoverFocusNodeSelected({required this.node});

  final NoteMindMapEntity node;

  @override
  List<Object> get props => [node];
}

final class DiscoverFocusAllNodesExpanded extends DiscoverFocusEvent {
  const DiscoverFocusAllNodesExpanded({required this.isExpanded});

  final bool isExpanded;
  @override
  List<Object> get props => [isExpanded];
}
