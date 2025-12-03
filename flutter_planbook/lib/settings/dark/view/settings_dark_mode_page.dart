import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:planbook_core/planbook_core.dart';

@RoutePage()
class SettingsDarkModePage extends StatelessWidget {
  const SettingsDarkModePage({super.key});

  static Route<void> route() {
    return CupertinoPageRoute(
      builder: (_) => const SettingsDarkModePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(l10n.darkMode),
        leading: const NavigationBarBackButton(),
      ),
      body: BlocSelector<AppBloc, AppState, DarkMode?>(
        selector: (state) => state.darkMode,
        builder: (context, darkMode) {
          final theme = Theme.of(context);
          return ListView(
            children: [
              SettingsRow(
                leading: const Icon(
                  Icons.circle,
                  color: Colors.green,
                ),
                title: Text(
                  l10n.modeAuto,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: darkMode == null ? const Icon(Icons.check) : null,
                onPressed: () {
                  context.read<AppBloc>().add(
                    const AppDarkModeChanged(),
                  );
                },
              ),
              Divider(
                indent: 56,
                height: 1,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              SettingsRow(
                leading: const Icon(
                  Icons.dark_mode,
                  color: Colors.blueGrey,
                ),
                title: Text(
                  l10n.dark,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: darkMode == DarkMode.dark
                    ? const Icon(Icons.check)
                    : null,
                onPressed: () {
                  context.read<AppBloc>().add(
                    const AppDarkModeChanged(
                      darkMode: DarkMode.dark,
                    ),
                  );
                },
              ),
              Divider(
                indent: 56,
                height: 1,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              SettingsRow(
                leading: const Icon(
                  Icons.light_mode,
                  color: Colors.yellow,
                ),
                title: Text(
                  l10n.light,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: darkMode == DarkMode.light
                    ? const Icon(Icons.check)
                    : null,
                onPressed: () {
                  context.read<AppBloc>().add(
                    const AppDarkModeChanged(
                      darkMode: DarkMode.light,
                    ),
                  );
                },
              ),
              Divider(
                indent: 56,
                height: 1,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          );
        },
      ),
    );
  }
}
