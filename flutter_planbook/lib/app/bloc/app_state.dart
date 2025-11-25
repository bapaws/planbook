part of 'app_bloc.dart';

final class AppState extends Equatable {
  const AppState({
    required this.darkMode,
    required this.appIcons,
    required this.seedColor,
  });

  final DarkMode? darkMode;

  final AppIcons appIcons;
  final AppSeedColors seedColor;

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
  }) => AppState(
    darkMode: darkMode == null ? this.darkMode : darkMode(),
    appIcons: appIcons ?? this.appIcons,
    seedColor: seedColor ?? this.seedColor,
  );
}
