import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_planbook/core/model/app_image_provider.dart';
import 'package:flutter_planbook/discover/journal/model/journal_date.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart'
    hide SettingsRepository;

part 'discover_journal_event.dart';
part 'discover_journal_state.dart';

class DiscoverJournalBloc
    extends Bloc<DiscoverJournalEvent, DiscoverJournalState> {
  DiscoverJournalBloc({
    required Jiffy now,
    required UsersRepository usersRepository,
  }) : _usersRepository = usersRepository,
       super(
         DiscoverJournalState(
           date: JournalDate(
             year: now.year,
             month: now.month,
             day: now.date,
           ),
         ),
       ) {
    on<DiscoverJournalRequested>(_onRequested, transformer: restartable());
    on<DiscoverJournalDateChanged>(_onDateChanged);
    on<DiscoverJournalYearChanged>(_onYearChanged);

    on<DiscoverJournalCalendarToggled>(_onCalendarToggled);

    on<DiscoverJournalLeftEnlargedToggled>(_onLeftEnlargedToggled);
    on<DiscoverJournalRightEnlargedToggled>(_onRightEnlargedToggled);
  }

  final UsersRepository _usersRepository;

  Future<void> _onRequested(
    DiscoverJournalRequested event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _usersRepository.onUserProfileChange.asyncMap(
        (userProfile) async {
          final image =
              userProfile?.coverByYear[event.year.toString()] ??
              'assets/images/cover.jpg';
          final colorScheme = await _coverColorSchemeByImage(image);
          return (image, colorScheme);
        },
      ),
      onData: (data) => state.copyWith(
        coverBackgroundImage: data.$1,
        coverColorScheme: data.$2,
        status: PageStatus.success,
      ),
    );
  }

  Future<void> _onDateChanged(
    DiscoverJournalDateChanged event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    if (event.date.year != state.date.year) {
      add(DiscoverJournalRequested(year: event.date.year));
    }
    emit(state.copyWith(date: event.date));
  }

  Future<void> _onYearChanged(
    DiscoverJournalYearChanged event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(state.copyWith(date: JournalDate.fromYear(event.year)));
    add(DiscoverJournalRequested(year: event.year));
  }

  Future<void> _onCalendarToggled(
    DiscoverJournalCalendarToggled event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(
      state.copyWith(
        isCalendarExpanded: event.isExpanded ?? !state.isCalendarExpanded,
      ),
    );
  }

  Future<void> _onLeftEnlargedToggled(
    DiscoverJournalLeftEnlargedToggled event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(
      state.copyWith(
        isLeftEnlarged: event.isEnlarged ?? !state.isLeftEnlarged,
        isRightEnlarged: false,
      ),
    );
  }

  Future<void> _onRightEnlargedToggled(
    DiscoverJournalRightEnlargedToggled event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(
      state.copyWith(
        isRightEnlarged: event.isEnlarged ?? !state.isRightEnlarged,
        isLeftEnlarged: false,
      ),
    );
  }

  Future<material.ColorScheme> _coverColorSchemeByImage(String image) async {
    return material.ColorScheme.fromImageProvider(
      provider: imageProviderForPath(image),
      // dynamicSchemeVariant: material.DynamicSchemeVariant.neutral,
    );
  }
}
