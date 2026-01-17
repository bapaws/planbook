import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/root/discover/model/root_discover_tab.dart';

part 'root_discover_event.dart';
part 'root_discover_state.dart';

class RootDiscoverBloc extends Bloc<RootDiscoverEvent, RootDiscoverState> {
  RootDiscoverBloc() : super(const RootDiscoverState()) {
    on<RootDiscoverTabSelected>(_onTabSelected);
  }

  Future<void> _onTabSelected(
    RootDiscoverTabSelected event,
    Emitter<RootDiscoverState> emit,
  ) async {
    emit(state.copyWith(tab: event.tab));
  }
}
