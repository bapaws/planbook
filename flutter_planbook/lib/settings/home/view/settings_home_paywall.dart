import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_home_upgrade_button.dart';

class SettingsPaywall extends StatelessWidget {
  const SettingsPaywall({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () {
        context.router.push(const AppPurchasesRoute());
      },
      child: Container(
        margin: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary,
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.appName} 👑',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  l10n.unlockPro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: theme.colorScheme.outline,
                ),
              ),
              child: const SettingsHomeUpgradeButton(),
            ),
          ],
        ),
      ),
    );
  }
}
