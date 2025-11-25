part of 'settings_home_bloc.dart';

sealed class SettingsHomeEvent extends Equatable {
  const SettingsHomeEvent();

  @override
  List<Object> get props => [];
}

final class SettingsHomeRequested extends SettingsHomeEvent {
  const SettingsHomeRequested();
}
