import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';

part 'app_activity_event.dart';
part 'app_activity_state.dart';

class AppActivityBloc extends Bloc<AppActivityEvent, AppActivityState> {
  AppActivityBloc({
    required AppActivityRepository appActivityRepository,
  }) : _appActivityRepository = appActivityRepository,
       super(const AppActivityState()) {
    on<AppActivityFetchRequested>(_onRequested);
    on<AppActivityNotShowAgain>(_onNotShowAgain);
    on<AppActivityWillShow>(_onWillShow);
  }

  final AppActivityRepository _appActivityRepository;

  Future<void> _onRequested(
    AppActivityFetchRequested event,
    Emitter<AppActivityState> emit,
  ) async {
    // if (kDebugMode) {
    //   await _appActivityRepository.fetchAll();
    // }

    final activities = await _appActivityRepository.fetch();
    // emit(state.copyWith(activities: activities));

    await emit.forEach(
      _appActivityRepository.onActivityChange,
      onData: (activities) => state.copyWith(activities: activities),
    );
  }

  Future<void> _onNotShowAgain(
    AppActivityNotShowAgain event,
    Emitter<AppActivityState> emit,
  ) async {
    _appActivityRepository.notShowAgain(event.message);
    emit(
      state.copyWith(
        activities: state.activities
            .where((activity) => activity.id != event.message.id)
            .toList(),
      ),
    );
  }

  Future<void> _onWillShow(
    AppActivityWillShow event,
    Emitter<AppActivityState> emit,
  ) async {
    _appActivityRepository.willShow(event.message, event.date);
    emit(
      state.copyWith(
        activities: state.activities
            .where((activity) => activity.id != event.message.id)
            .toList(),
      ),
    );
  }
}
