import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class AppActivityAlertPage extends StatelessWidget {
  const AppActivityAlertPage({
    required this.activity,
    super.key,
  });

  final ActivityMessageEntity activity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final double width = min(MediaQuery.of(context).size.width - 48, 360);
    return Column(
      // mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: width,
              height: 72,
              decoration: ShapeDecoration(
                shape: const RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                color: colorScheme.surfaceContainerLowest,
              ),
            ),
            Text(
                  activity.emoji,
                  style: const TextStyle(fontSize: 96 + 12),
                )
                .animate()
                .moveY(
                  begin: -100,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.bounceOut,
                )
                .scaleXY(
                  begin: 0.5,
                  end: 1,
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
          ],
        ),
        Container(
          width: width,
          decoration: ShapeDecoration(
            shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            color: colorScheme.surfaceContainerLowest,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Text(
                  activity.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (activity.content != null) ...[
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: MarkdownBody(
                      data: activity.content!,
                      styleSheet: MarkdownStyleSheet(
                        p: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTapLink: (text, href, title) async {
                        if (href != null) {
                          await launchUrl(Uri.parse(href));
                        }
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton.tinted(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: const Size.square(kMinInteractiveDimension),
                      onPressed: () async {
                        context.read<AppActivityBloc>().add(
                          AppActivityNotShowAgain(
                            message: activity,
                          ),
                        );
                        await context.router.maybePop();
                      },
                      child: Text(
                        context.l10n.notShowAgain,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton.filled(
                      color: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: const Size.square(kMinInteractiveDimension),
                      onPressed: () async {
                        if (activity.openURL != null) {
                          await launchUrl(Uri.parse(activity.openURL!));
                        }
                        if (context.mounted) {
                          context.read<AppActivityBloc>().add(
                            AppActivityNotShowAgain(
                              message: activity,
                            ),
                          );
                          await context.router.maybePop();
                        }
                      },
                      child: Text(
                        activity.openTitle ?? context.l10n.done,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.surfaceContainerLowest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          minimumSize: Size.zero,
          child: Text(
            context.l10n.activityDetails,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
          onPressed: () {
            context.router.push(AppActivityRoute(activity: activity));
          },
        ),
        const SizedBox(height: 96),
      ],
    );
  }
}
