import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'root_journal_event.dart';
part 'root_journal_state.dart';

class RootJournalBloc extends Bloc<RootJournalEvent, RootJournalState> {
  RootJournalBloc() : super(RootJournalInitial()) {
    on<RootJournalEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
