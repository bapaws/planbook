part of 'app_bloc.dart';

sealed class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

final class AppInitialized extends AppEvent {
  const AppInitialized();
}

final class AppLaunched extends AppEvent {
  const AppLaunched({required this.l10n});

  final AppLocalizations l10n;

  @override
  List<Object?> get props => [l10n];
}

final class AppUserRequested extends AppEvent {
  const AppUserRequested();
}

final class AppDarkModeChanged extends AppEvent {
  const AppDarkModeChanged({
    this.darkMode,
  });

  final DarkMode? darkMode;

  @override
  List<Object?> get props => [darkMode];
}

final class AppSeedColorChanged extends AppEvent {
  const AppSeedColorChanged({
    required this.seedColor,
  });

  final AppSeedColors seedColor;
}

final class AppBackgroundRequested extends AppEvent {
  const AppBackgroundRequested();
}

final class AppApkVersionRequested extends AppEvent {
  const AppApkVersionRequested();
}

final class AppApkDownloadRequested extends AppEvent {
  const AppApkDownloadRequested({required this.l10n});

  final AppLocalizations l10n;

  @override
  List<Object?> get props => [l10n];
}

final class AppApkDownloadProgressUpdated extends AppEvent {
  const AppApkDownloadProgressUpdated(this.progress);

  final double progress;

  @override
  List<Object?> get props => [progress];
}
