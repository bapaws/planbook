import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/purchases/view/app_purchases_product_view.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppPurchasesFooter extends StatelessWidget {
  const AppPurchasesFooter({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AppPurchasesBloc, AppPurchasesState>(
      builder: (context, state) {
        final storeProducts = state.storeProducts;
        if (storeProducts.isEmpty) {
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
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                BlocSelector<
                  AppPurchasesBloc,
                  AppPurchasesState,
                  StoreProduct?
                >(
                  selector: (state) => state.selectedStoreProduct,
                  builder: (context, selectedStoreProduct) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: spacing),
                        for (final product in storeProducts) ...[
                          AppPurchasesProductView(
                            product: product,
                            itemWidth: productItemWidth,
                            isSelected: selectedStoreProduct == product,
                            onPressed: () {
                              context.read<AppPurchasesBloc>().add(
                                AppPurchasesProductSelected(product),
                              );
                            },
                          ),
                          const SizedBox(width: spacing),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (!AppPurchases.instance.isAndroidChina)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      if (AppPurchases.instance.isAndroidChina) {
                        final isAgreed = await _showAgreementDialog(context);
                        if ((isAgreed ?? false) && context.mounted) {
                          context.read<AppPurchasesBloc>()
                            ..add(
                              const AppPurchasesAgreedToConditions(
                                isAgreed: true,
                              ),
                            )
                            ..add(const AppPurchasesPurchased());
                        }
                      } else {
                        context.read<AppPurchasesBloc>().add(
                          const AppPurchasesPurchased(),
                        );
                      }
                    },
                    minimumSize: Size.zero,
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
                  )
                else ...[
                  SizedBox(
                    width: productItemWidth * 3 + spacing * 2,
                    child: Row(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: const Color(0xFF027aff),
                            borderRadius: BorderRadius.circular(
                              kMinInteractiveDimension,
                            ),
                            onPressed: () async {
                              var isAgreed = context
                                  .read<AppPurchasesBloc>()
                                  .state
                                  .isAgreedToConditions;
                              if (!isAgreed) {
                                isAgreed =
                                    (await _showAgreementDialog(context)) ??
                                    false;
                              }
                              if (isAgreed && context.mounted) {
                                context.read<AppPurchasesBloc>()
                                  ..add(
                                    const AppPurchasesAgreedToConditions(
                                      isAgreed: true,
                                    ),
                                  )
                                  ..add(const AppPurchasesPurchased());
                              }
                            },
                            child: Text(
                              '支付宝支付',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    onPressed: () async {
                      final isAgreed = context
                          .read<AppPurchasesBloc>()
                          .state
                          .isAgreedToConditions;
                      context.read<AppPurchasesBloc>().add(
                        AppPurchasesAgreedToConditions(isAgreed: !isAgreed),
                      );
                    },
                    minimumSize: Size.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BlocSelector<AppPurchasesBloc, AppPurchasesState, bool>(
                          selector: (state) => state.isAgreedToConditions,
                          builder: (context, isAgreedToConditions) => Icon(
                            isAgreedToConditions
                                ? FontAwesomeIcons.circleCheck
                                : FontAwesomeIcons.circle,
                            size: 16,
                            color: isAgreedToConditions
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildAgreementText(context),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showAgreementDialog(BuildContext context) async {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: _buildAgreementText(context),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(context.l10n.cancel),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementText(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        children: [
          const TextSpan(text: '开通前请阅读'),
          TextSpan(
            text: '《会员协议》',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrlString(
                'https://uxsyr9xrl46.feishu.cn/wiki/Y8qhw3DLriHC1CkeT2pcUvbunye',
              ),
          ),
        ],
      ),
    );
  }
}
