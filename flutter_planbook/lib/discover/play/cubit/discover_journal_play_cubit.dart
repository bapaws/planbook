import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'discover_journal_play_state.dart';

class DiscoverJournalPlayCubit extends Cubit<DiscoverJournalPlayState> {
  DiscoverJournalPlayCubit()
    : super(
        DiscoverJournalPlayState(
          from: Jiffy.now().startOf(Unit.month),
          to: Jiffy.now().endOf(Unit.month),
        ),
      );

  void onFromChanged(Jiffy from) {
    emit(state.copyWith(from: from));
  }

  void onToChanged(Jiffy to) {
    emit(state.copyWith(to: to));
  }
}
