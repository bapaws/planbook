part of 'app_bloc.dart';

enum AppApkDownloadStatus {
  idle,
  downloading,
  installSuccess,
  installError,
}

final class AppState extends Equatable {
  const AppState({
    required this.darkMode,
    required this.seedColor,
    this.background,
    this.user,
    this.apkVersion,
    this.apkHasNewVersion = false,
    this.apkDownloadStatus = AppApkDownloadStatus.idle,
    this.apkDownloadErrorMessage,
    this.apkDownloadProgress = 0,
  });

  final DarkMode? darkMode;
  final AppSeedColors seedColor;
  final AppBackgroundEntity? background;

  final UserEntity? user;

  final String? apkVersion;
  final bool apkHasNewVersion;
  final AppApkDownloadStatus apkDownloadStatus;
  final String? apkDownloadErrorMessage;
  final double apkDownloadProgress;

  material.ThemeData getTheme(material.Brightness brightness) =>
      switch (darkMode) {
        DarkMode.dark => seedColor.dark,
        DarkMode.light => seedColor.light,
        null =>
          brightness == material.Brightness.dark
              ? seedColor.dark
              : seedColor.light,
      };

  @override
  List<Object?> get props => [
    darkMode,
    background,
    seedColor,
    user,
    apkVersion,
    apkHasNewVersion,
    apkDownloadStatus,
    apkDownloadErrorMessage,
    apkDownloadProgress,
  ];

  AppState copyWith({
    ValueGetter<DarkMode?>? darkMode,
    AppBackgroundEntity? background,
    AppSeedColors? seedColor,
    UserEntity? user,
    String? apkVersion,
    bool? apkHasNewVersion,
    AppApkDownloadStatus? apkDownloadStatus,
    String? apkDownloadErrorMessage,
    double? apkDownloadProgress,
    bool clearApkDownloadError = false,
  }) =>
      AppState(
        darkMode: darkMode == null ? this.darkMode : darkMode(),
        background: background ?? this.background,
        seedColor: seedColor ?? this.seedColor,
        user: user ?? this.user,
        apkVersion: apkVersion ?? this.apkVersion,
        apkHasNewVersion: apkHasNewVersion ?? this.apkHasNewVersion,
        apkDownloadStatus: apkDownloadStatus ?? this.apkDownloadStatus,
        apkDownloadErrorMessage: clearApkDownloadError
            ? null
            : (apkDownloadErrorMessage ?? this.apkDownloadErrorMessage),
        apkDownloadProgress:
            apkDownloadProgress ?? this.apkDownloadProgress,
      );
}
