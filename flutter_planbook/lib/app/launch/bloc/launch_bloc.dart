import 'package:app_links/app_links.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'launch_event.dart';
part 'launch_state.dart';

class LaunchBloc extends Bloc<LaunchEvent, LaunchState> {
  LaunchBloc() : super(const LaunchState()) {
    on<LaunchAppLinks>(_onAppLinks);

    on<LaunchAnimationStatusChanged>(_onAnimationStatusChanged);
    on<LaunchAnimationFinished>(_onAnimationFinished);
  }

  final _appLinks = AppLinks(); // AppLinks is singleton

  Future<void> _onAppLinks(
    LaunchAppLinks event,
    Emitter<LaunchState> emit,
  ) async {
    await emit.forEach(
      _appLinks.uriLinkStream,
      onData: (data) => state.copyWith(appLinksUri: data),
    );
  }

  Future<void> _onAnimationStatusChanged(
    LaunchAnimationStatusChanged event,
    Emitter<LaunchState> emit,
  ) async {
    emit(state.copyWith(animationStatus: event.status));
  }

  Future<void> _onAnimationFinished(
    LaunchAnimationFinished event,
    Emitter<LaunchState> emit,
  ) async {
    emit(state.copyWith(isAnimationFinished: true));
  }
}
