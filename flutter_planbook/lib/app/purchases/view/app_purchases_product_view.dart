import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

class AppPurchasesProductView extends StatelessWidget {
  const AppPurchasesProductView({
    required this.product,
    this.originalProduct,
    this.onPressed,
    this.isSelected = false,
    this.itemWidth = 100,
    super.key,
  });

  final StoreProduct product;
  final StoreProduct? originalProduct;
  final VoidCallback? onPressed;
  final bool isSelected;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      minimumSize: Size(itemWidth, itemWidth),
      child: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: Durations.short4,
            width: itemWidth,
            height: itemWidth,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.tertiaryContainer
                  : theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.priceString,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
                  ),
                ),
                if (originalProduct != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    originalProduct!.priceString,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ),
          BlocSelector<AppPurchasesBloc, AppPurchasesState, String?>(
            selector: (state) => state.savePercentId,
            builder: (context, savePercentId) => savePercentId == product.id
                ? PositionedDirectional(
                    top: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        context.l10n.savePercent(50),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
