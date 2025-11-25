import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
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
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.centerEnd,
        children: [
          PositionedDirectional(
            top: 32,
            end: -64,
            child: SvgPicture.asset(
              'assets/images/paywall.svg',
              width: 150,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Row(
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
                    vertical: 16,
                    horizontal: 24,
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
                              activePackage?.storeProduct.title ??
                                  l10n.upgradePro,
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
        ],
      ),
    );
  }
}
