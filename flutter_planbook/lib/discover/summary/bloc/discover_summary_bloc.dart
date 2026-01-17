import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'discover_summary_event.dart';
part 'discover_summary_state.dart';

class DiscoverSummaryBloc extends Bloc<DiscoverSummaryEvent, DiscoverSummaryState> {
  DiscoverSummaryBloc() : super(DiscoverSummaryInitial()) {
    on<DiscoverSummaryEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
