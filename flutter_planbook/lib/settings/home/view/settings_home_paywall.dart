import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shimmer/shimmer.dart';

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
          vertical: 24,
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
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (context.read<AppPurchasesBloc>().state.isLifetime) {
                  return;
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                  ),
                ),
                child: Shimmer(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.blue,
                      Colors.red,
                    ],
                  ),
                  child:
                      BlocSelector<
                        AppPurchasesBloc,
                        AppPurchasesState,
                        Package?
                      >(
                        selector: (state) => state.activePackage,
                        builder: (context, activePackage) {
                          return Text(
                            activePackage?.storeProduct.title ?? l10n.upgrade,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
