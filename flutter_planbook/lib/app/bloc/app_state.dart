part of 'app_bloc.dart';

final class AppState extends Equatable {
  const AppState({
    required this.darkMode,
    required this.appIcons,
    required this.seedColor,
    this.user,
  });

  final DarkMode? darkMode;

  final AppIcons appIcons;
  final AppSeedColors seedColor;

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
  List<Object?> get props => [darkMode, appIcons, seedColor];

  AppState copyWith({
    ValueGetter<DarkMode?>? darkMode,
    AppIcons? appIcons,
    AppSeedColors? seedColor,
    UserEntity? user,
  }) => AppState(
    darkMode: darkMode == null ? this.darkMode : darkMode(),
    appIcons: appIcons ?? this.appIcons,
    seedColor: seedColor ?? this.seedColor,
    user: user ?? this.user,
  );
}
