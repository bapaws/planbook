import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/bloc/settings_home_bloc.dart';
import 'package:flutter_planbook/settings/home/view/settings_home_paywall.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:flutter_planbook/settings/home/view/settings_section_header.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/user_entity.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
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
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(context.l10n.settings),
        leading: const NavigationBarBackButton(),
      ),
      body: ListView(
        children: [
          BlocSelector<AppPurchasesBloc, AppPurchasesState, bool>(
            selector: (state) => state.isLifetime,
            builder: (context, state) {
              return state ? const SizedBox.shrink() : const SettingsPaywall();
            },
          ),
          CupertinoButton(
            // padding: EdgeInsets.zero,
            onPressed: () {
              final user = context.read<AppBloc>().state.user;
              if (user == null) {
                context.router.push(const SignHomeRoute());
              } else {
                context.router.push(const MineProfileRoute());
              }
            },
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
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  BlocSelector<AppBloc, AppState, UserEntity?>(
                    selector: (state) => state.user,
                    builder: (context, user) => Text(
                      user?.displayName ?? context.l10n.notLoggedIn,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
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
              FontAwesomeIcons.solidCalendarCheck,
              color: Colors.teal,
              size: 20,
            ),
            title: Text(l10n.task),
            onPressed: () {
              context.router.push(const SettingsTaskRoute());
            },
          ),
          SettingsSectionHeader(
            title: l10n.appearance,
          ),
          SettingsRow(
            leading: const Icon(
              FontAwesomeIcons.solidImage,
              color: Colors.cyan,
              size: 20,
            ),
            title: Text(l10n.background),
            onPressed: () {
              context.router.push(const SettingsBackgroundRoute());
            },
          ),
          SettingsRow(
            leading: const Icon(
              FontAwesomeIcons.solidMoon,
              color: Colors.blueGrey,
              size: 20,
            ),
            title: Text(l10n.darkMode),
            onPressed: () {
              context.router.push(const SettingsDarkModeRoute());
            },
          ),
          SettingsRow(
            leading: const Icon(
              FontAwesomeIcons.palette,
              color: Colors.pink,
              size: 20,
            ),
            title: Text(l10n.seedColor),
            onPressed: () {
              context.router.push(const SettingsSeedColorRoute());
            },
          ),
          // SettingsRow(
          //   leading: const Icon(
          //     Icons.app_registration,
          //     color: Colors.pink,
          //   ),
          //   title: Text(
          //     l10n.appIcon,
          //     style: theme.textTheme.bodyLarge?.copyWith(
          //       color: theme.colorScheme.onSurface,
          //     ),
          //   ),
          //   onPressed: () => context.router.push(const SettingsIconRoute()),
          // ),
          SettingsSectionHeader(
            title: l10n.other,
          ),
          if (Platform.isIOS || Platform.isMacOS) ...[
            SettingsRow(
              leading: const Icon(
                FontAwesomeIcons.solidStar,
                color: Colors.amber,
                size: 20,
              ),
              title: Text(l10n.rate),
              onPressed: () {
                launchUrlString(
                  'https://apps.apple.com/app/id6737596725?action=write-review',
                );
              },
            ),
          ],
          SettingsRow(
            leading: const Icon(
              FontAwesomeIcons.solidMessage,
              color: Colors.green,
              size: 20,
            ),
            title: Text(l10n.feedback),
            onPressed: () {
              context.router.push(const FeedbackRoute());
            },
          ),
          // SettingsRow(
          //   leading: const Icon(
          //     Icons.help,
          //     color: Colors.blue,
          //   ),
          //   title: Text(
          //     l10n.help,
          //     style: theme.textTheme.bodyLarge?.copyWith(
          //       color: theme.colorScheme.onSurface,
          //     ),
          //   ),
          //   onPressed: () {
          //     launchUrlString(context.l10n.helpUrl);
          //   },
          // ),
          SettingsRow(
            leading: const Icon(
              FontAwesomeIcons.circleInfo,
              color: Colors.orange,
              size: 20,
            ),
            title: Text(l10n.about),
            onPressed: () {
              context.router.push(const AboutRoute());
            },
          ),
          const SizedBox(height: kToolbarHeight),
        ],
      ),
    );
  }
}
