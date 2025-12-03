import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/purchases/view/app_purchases_product_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class AppPurchasesFooter extends StatelessWidget {
  const AppPurchasesFooter({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AppPurchasesBloc, AppPurchasesState>(
      builder: (context, state) {
        final availablePackages = state.availablePackages;
        if (availablePackages.isEmpty) {
          context
              .read<AppPurchasesBloc>()
              .add(const AppPurchasesPackageRequested());
          return const SizedBox.shrink();
        }

        final size = MediaQuery.of(context).size;
        const double spacing = 24;
        final double productItemWidth = min(
          (size.width - spacing * 4) / 3,
          120,
        );
        return Container(
          padding: const EdgeInsets.only(
            top: spacing,
            bottom: 8,
          ),
          color: theme.colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                BlocSelector<AppPurchasesBloc, AppPurchasesState, Package?>(
                  selector: (state) => state.selectedPackage,
                  builder: (context, selectedPackage) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: spacing),
                        for (final package in availablePackages) ...[
                          AppPurchasesProductView(
                            package: package,
                            originalPackage: context
                                .read<AppPurchasesBloc>()
                                .state
                                .originalPackages
                                .firstWhereOrNull(
                                  (e) => e.storeProduct.identifier.startsWith(
                                    package.storeProduct.identifier,
                                  ),
                                ),
                            itemWidth: productItemWidth,
                            isSelected: selectedPackage == package,
                            onPressed: () {
                              context
                                  .read<AppPurchasesBloc>()
                                  .add(AppPurchasesPackageSelected(package));
                            },
                          ),
                          const SizedBox(width: spacing),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  child: Container(
                    width: productItemWidth * 3 + spacing * 2,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(
                        kMinInteractiveDimension,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        Text(
                          context.l10n.getPro,
                          style: theme.textTheme.titleMedium!.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  onPressed: () {
                    context.read<AppPurchasesBloc>().add(
                          const AppPurchasesPurchased(),
                        );
                  },
                ),
                if (state.originalPackages.isNotEmpty)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    minSize: 0,
                    child: SizedBox(
                      width: productItemWidth * 3 + spacing * 2,
                      child: Row(
                        children: [
                          const Spacer(),
                          Text(
                            context.l10n.supportUsFullPrice,
                            style: theme.textTheme.labelSmall!.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    onPressed: () {
                      context.read<AppPurchasesBloc>().add(
                            const AppPurchasesSupportUsFullPrice(),
                          );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
