import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:flutter_planbook/core/view/app_pro_view.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/bloc/settings_home_bloc.dart';
import 'package:flutter_planbook/settings/home/view/settings_home_download_row.dart';
import 'package:flutter_planbook/settings/home/view/settings_home_paywall.dart';
import 'package:flutter_planbook/settings/home/view/settings_home_upgrade_button.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:flutter_planbook/settings/home/view/settings_section_header.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/user_entity.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:planbook_repository/assets/assets_repository.dart';
import 'package:url_launcher/url_launcher_string.dart';

@RoutePage()
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        context.read<AppBloc>().add(const AppApkVersionRequested());
        return SettingsHomeBloc(settingsRepository: context.read())
          ..add(const SettingsHomeRequested());
      },
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
        actions: const [
          SettingsHomeUpgradeButton(),
        ],
      ),
      body: ListView(
        children: [
          BlocSelector<AppPurchasesBloc, AppPurchasesState, bool>(
            selector: (state) => state.isPremium,
            builder: (context, isPremium) {
              return isPremium
                  ? const SizedBox.shrink()
                  : const SettingsPaywall();
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
              child: BlocSelector<AppBloc, AppState, UserEntity?>(
                selector: (state) => state.user,
                builder: (context, user) => Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.surfaceContainerHighest,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: user?.avatar == null
                          ? SvgPicture.asset(
                              'assets/images/logo.svg',
                              width: 40,
                              height: 40,
                            )
                          : AppNetworkImage(
                              url: user?.avatar,
                              bucket: ResBucket.userAvatars,
                              width: 40,
                              height: 40,
                            ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? context.l10n.notLoggedIn,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (user?.profile?.expiresAt != null)
                          _buildExpiresAt(context, user!.profile!.expiresAt!),
                      ],
                    ),
                    const Spacer(),
                    BlocSelector<AppPurchasesBloc, AppPurchasesState, bool>(
                      selector: (state) => state.isPremium,
                      builder: (context, isPremium) => AppProButton(
                        isPremium: isPremium,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const CupertinoListTileChevron(),
                  ],
                ),
              ),
            ),
          ),
          if (AppPurchases.instance.isAndroidChina)
            const SettingsHomeDownloadRow(),
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
          BlocSelector<AppActivityBloc, AppActivityState, bool>(
            selector: (state) => state.activities.isNotEmpty,
            builder: (context, isNotEmpty) {
              return isNotEmpty
                  ? SettingsRow(
                      leading: const Icon(
                        FontAwesomeIcons.gift,
                        color: Colors.red,
                        size: 20,
                      ),
                      title: Text(
                        l10n.rewardActivities,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      onPressed: () {
                        context.router.push(const AppActivityListRoute());
                      },
                    )
                  : const SizedBox.shrink();
            },
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

  Widget _buildExpiresAt(BuildContext context, DateTime expiresAt) {
    final theme = Theme.of(context);
    final date = Jiffy.parseFromDateTime(expiresAt);
    final formattedDate = date.yMMMd;
    final text = context.l10n.expiresAtDescription(formattedDate);
    final parts = text.split(formattedDate);
    final diff = expiresAt.difference(DateTime.now()).inDays;
    return DefaultTextStyle(
      style: theme.textTheme.labelSmall!.copyWith(
        color: theme.colorScheme.outline,
      ),
      child: Row(
        children: [
          Text(
            parts[0],
          ),
          Text(
            formattedDate,
            style: theme.textTheme.labelSmall?.copyWith(
              color: diff <= 10
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            parts[1],
          ),
        ],
      ),
    );
  }
}
