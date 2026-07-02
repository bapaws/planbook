import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:flutter_planbook/settings/language/model/app_locale_option.dart';
import 'package:planbook_core/planbook_core.dart';

@RoutePage()
class SettingsLanguagePage extends StatelessWidget {
  const SettingsLanguagePage({super.key});

  static Route<void> route() {
    return CupertinoPageRoute(
      builder: (_) => const SettingsLanguagePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(l10n.language),
        leading: const NavigationBarBackButton(),
      ),
      body: BlocSelector<AppBloc, AppState, Locale?>(
        selector: (state) => state.locale,
        builder: (context, locale) {
          final theme = Theme.of(context);
          return ListView(
            children: [
              SettingsRow(
                leading: const Icon(
                  Icons.language,
                  color: Colors.green,
                ),
                title: Text(
                  l10n.modeAuto,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: locale == null ? const Icon(Icons.check) : null,
                onPressed: () {
                  context.read<AppBloc>().add(const AppLocaleChanged());
                },
              ),
              for (final option in AppLocaleOption.options)
                SettingsRow(
                  leading: const Icon(
                    Icons.translate,
                    color: Colors.blueGrey,
                  ),
                  title: Text(
                    option.nativeName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: AppLocaleOption.isSameLocale(locale, option.locale)
                      ? const Icon(Icons.check)
                      : null,
                  onPressed: () {
                    context.read<AppBloc>().add(
                      AppLocaleChanged(locale: option.locale),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
