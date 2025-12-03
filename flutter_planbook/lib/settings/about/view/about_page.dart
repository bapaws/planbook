import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/launch/view/animated_logo.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/about/cubit/about_cubit.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher_string.dart';

@RoutePage()
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AboutCubit()..onRequested(),
      child: _AboutPage(),
    );
  }
}

class _AboutPage extends StatelessWidget {
  _AboutPage();

  final ScreenshotController screenshotController = ScreenshotController();

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
                if (kDebugMode)
                  Center(
                    child: SizedBox(
                      width: 1024,
                      height: 1024,
                      child: Screenshot(
                        controller: screenshotController,
                        child: ColoredBox(
                          color: theme.colorScheme.surfaceContainerLowest,
                          child: LogoView(
                            width: 1024,
                            height: 1024,
                            strokeColor: theme.colorScheme.primaryContainer,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const AnimatedLogo(),
                const SizedBox(
                  height: 8,
                ),
                CupertinoButton(
                  onPressed: kDebugMode
                      ? () {
                          _capture(context);
                        }
                      : null,
                  child: Text(
                    l10n.appName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
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

  void _capture(BuildContext context) {
    final seedColor = context.read<AppBloc>().state.seedColor;
    final folder = Theme.of(context).brightness == Brightness.light
        ? 'light'
        : 'dark';
    final name =
        seedColor.name.substring(0, 1).toUpperCase() +
        seedColor.name.substring(1);
    screenshotController.capture().then((image) async {
      if (image != null) {
        await ImageGallerySaver.saveImage(image);

        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File(
          '${directory.path}/$folder/Logo-$name.png',
        ).create();
        await imagePath.writeAsBytes(image);
      }
    });
  }
}
