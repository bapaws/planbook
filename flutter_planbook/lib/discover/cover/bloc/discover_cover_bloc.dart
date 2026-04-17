import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/cover/repository/discover_cover_repository.dart';
import 'package:planbook_core/planbook_core.dart';

part 'discover_cover_event.dart';
part 'discover_cover_state.dart';

class DiscoverCoverBloc extends Bloc<DiscoverCoverEvent, DiscoverCoverState> {
  DiscoverCoverBloc({
    required DiscoverCoverRepository coverRepository,
    required int year,
    String? currentCoverImage,
  }) : _coverRepository = coverRepository,
       super(
         DiscoverCoverState(
           year: year,
           selectedCoverPath: currentCoverImage,
         ),
       ) {
    on<DiscoverCoverRequested>(_onRequested);
    on<DiscoverCoverColorSchemeRequested>(
      _onColorSchemeRequested,
      transformer: concurrent(),
    );
    on<DiscoverCoverSelected>(_onSelected, transformer: sequential());
  }

  final DiscoverCoverRepository _coverRepository;

  Future<void> _onRequested(
    DiscoverCoverRequested event,
    Emitter<DiscoverCoverState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    for (final cover in DiscoverCoverState.defaultBuiltinCovers) {
      add(DiscoverCoverColorSchemeRequested(coverPath: cover));
    }
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _onColorSchemeRequested(
    DiscoverCoverColorSchemeRequested event,
    Emitter<DiscoverCoverState> emit,
  ) async {
    final coverProvider = _coverRepository.imageProviderFor(event.coverPath);
    final coverColorScheme = await ColorScheme.fromImageProvider(
      provider: coverProvider,
    );
    final covers = [...state.builtinCovers, event.coverPath];
    emit(
      state.copyWith(
        builtinCovers: covers,
        builtinColorSchemes: [...state.builtinColorSchemes, coverColorScheme],
        status: covers.length == DiscoverCoverState.defaultBuiltinCovers.length
            ? PageStatus.success
            : PageStatus.loading,
      ),
    );
  }

  Future<void> _onSelected(
    DiscoverCoverSelected event,
    Emitter<DiscoverCoverState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _coverRepository.saveYearCoverPath(
      year: state.year,
      coverPath: event.coverPath,
    );
    emit(state.copyWith(status: PageStatus.dispose));
  }
}
