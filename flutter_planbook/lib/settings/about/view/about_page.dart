import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/about/cubit/about_cubit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:url_launcher/url_launcher_string.dart';

@RoutePage()
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AboutCubit()..onRequested(),
      child: const _AboutPage(),
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.about),
        leading: const NavigationBarBackButton(),
      ),
      body: SafeArea(
        child: BlocBuilder<AboutCubit, AboutState>(
          builder: (context, state) {
            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  l10n.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Center(
                  child: Text(
                    '${state.appVersion}(${state.builderNumber})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Copyright © 2021-${DateTime.now().year} Bapaws. '
                    'All rights reserved.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        l10n.privacy,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                      onPressed: () {
                        launchUrlString(l10n.privacyAgreementUrl);
                      },
                    ),
                    const Text('  |  '),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        l10n.terms,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                      onPressed: () {
                        launchUrlString(l10n.userAgreementUrl);
                      },
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
