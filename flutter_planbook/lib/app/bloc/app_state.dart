part of 'app_bloc.dart';

final class AppState extends Equatable {
  const AppState({
    required this.darkMode,
    required this.seedColor,
    this.background,
    this.user,
  });

  final DarkMode? darkMode;
  final AppSeedColors seedColor;
  final AppBackgroundEntity? background;

  final UserEntity? user;

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
  ];

  AppState copyWith({
    ValueGetter<DarkMode?>? darkMode,
    AppBackgroundEntity? background,
    AppSeedColors? seedColor,
    UserEntity? user,
  }) => AppState(
    darkMode: darkMode == null ? this.darkMode : darkMode(),
    background: background ?? this.background,
    seedColor: seedColor ?? this.seedColor,
    user: user ?? this.user,
  );
}
