import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/root/discover/model/root_discover_tab.dart';
import 'package:jiffy/jiffy.dart';

part 'root_discover_event.dart';
part 'root_discover_state.dart';

class RootDiscoverBloc extends Bloc<RootDiscoverEvent, RootDiscoverState> {
  RootDiscoverBloc() : super(const RootDiscoverState()) {
    on<RootDiscoverTabSelected>(_onTabSelected);
    on<RootDiscoverAutoPlayRangeChanged>(_onAutoPlayRangeChanged);
  }

  Future<void> _onTabSelected(
    RootDiscoverTabSelected event,
    Emitter<RootDiscoverState> emit,
  ) async {
    emit(state.copyWith(tab: event.tab));
  }

  Future<void> _onAutoPlayRangeChanged(
    RootDiscoverAutoPlayRangeChanged event,
    Emitter<RootDiscoverState> emit,
  ) async {
    emit(state.copyWith(autoPlayFrom: event.from, autoPlayTo: event.to));
  }
}
