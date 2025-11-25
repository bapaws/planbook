import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/bloc/settings_home_bloc.dart';
import 'package:flutter_planbook/settings/home/view/settings_home_paywall.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:flutter_planbook/settings/home/view/settings_section_header.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:url_launcher/url_launcher_string.dart';

@RoutePage()
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsHomeBloc(
        settingsRepository: context.read(),
      ),
      child: const _SettingsHomePage(),
    );
  }
}

class _SettingsHomePage extends StatelessWidget {
  const _SettingsHomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(context.l10n.settings),
        leading: const CupertinoNavigationBarBackButton(),
      ),
      body: BlocBuilder<SettingsHomeBloc, SettingsHomeState>(
        builder: (context, state) {
          return ListView(
            children: [
              BlocSelector<AppPurchasesBloc, AppPurchasesState, bool>(
                selector: (state) => state.isLifetime,
                builder: (context, state) {
                  return state
                      ? Container()
                      : const Padding(
                          padding: EdgeInsets.only(
                            top: 32,
                            bottom: kMinInteractiveDimension,
                          ),
                          child: SettingsPaywall(),
                        );
                },
              ),
              CupertinoButton(
                // padding: EdgeInsets.zero,
                onPressed: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage(
                          'assets/logos/dark/Logo-Yellow.png',
                        ),
                        radius: 16,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      const CupertinoListTileChevron(),
                    ],
                  ),
                ),
              ),
              SettingsSectionHeader(
                title: l10n.general,
              ),
              SettingsRow(
                leading: const Icon(
                  Icons.dark_mode,
                  color: Colors.blueGrey,
                ),
                title: Text(
                  l10n.darkMode,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () {
                  context.router.push(const SettingsDarkModeRoute());
                },
              ),
              Divider(
                indent: 56,
                height: 1,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              SettingsRow(
                leading: const Icon(
                  Icons.palette,
                  color: Colors.cyan,
                ),
                title: Text(
                  l10n.seedColor,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () {
                  context.router.push(const SettingsSeedColorRoute());
                },
              ),
              Divider(
                indent: 56,
                height: 1,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              SettingsRow(
                leading: const Icon(
                  Icons.app_registration,
                  color: Colors.pink,
                ),
                title: Text(
                  l10n.appIcon,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () => context.router.push(const SettingsIconRoute()),
              ),
              Divider(
                indent: 56,
                height: 1,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              SettingsSectionHeader(
                title: l10n.other,
              ),
              if (Platform.isIOS || Platform.isMacOS) ...[
                SettingsRow(
                  leading: const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  title: Text(
                    l10n.rate,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  onPressed: () {
                    launchUrlString(
                      'https://apps.apple.com/app/id6737596725?action=write-review',
                    );
                  },
                ),
                Divider(
                  indent: 56,
                  height: 1,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
              SettingsRow(
                leading: const Icon(
                  Icons.feedback,
                  color: Colors.green,
                ),
                title: Text(
                  l10n.feedback,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () {
                  context.router.push(const FeedbackRoute());
                },
              ),
              Divider(
                indent: 56,
                height: 1,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              SettingsRow(
                leading: const Icon(
                  Icons.help,
                  color: Colors.blue,
                ),
                title: Text(
                  l10n.help,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () {
                  launchUrlString(context.l10n.helpUrl);
                },
              ),
              Divider(
                indent: 56,
                height: 1,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              SettingsRow(
                leading: const Icon(
                  Icons.info,
                  color: Colors.orange,
                ),
                title: Text(
                  l10n.about,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () {
                  context.router.push(const AboutRoute());
                },
              ),
              Divider(
                indent: 56,
                height: 1,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: kToolbarHeight),
            ],
          );
        },
      ),
    );
  }
}
