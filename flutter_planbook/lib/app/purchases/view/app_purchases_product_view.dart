import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';

class AppPurchasesProductView extends StatelessWidget {
  const AppPurchasesProductView({
    required this.product,
    this.onPressed,
    this.isSelected = false,
    this.savePercent,
    this.showBestValueBadge = false,
    super.key,
  });

  final StoreProduct product;
  final VoidCallback? onPressed;
  final bool isSelected;

  /// 相对月费的节省比例；仅推荐档展示
  final int? savePercent;
  final bool showBestValueBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = theme.colorScheme.tertiary;
    final badge = _badgeText(l10n);
    final subtitle = _subtitleText(l10n);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      minimumSize: Size.zero,
      child: AnimatedContainer(
        duration: Durations.short4,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.tertiaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _SelectionIndicator(
              isSelected: isSelected,
              accent: accent,
              outline: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _planTitle(l10n),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              // fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              product.priceString,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? accent : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _planTitle(AppLocalizations l10n) {
    // 国内是时长买断（非自动续订）：1个月 / 1年 / 终身
    if (AppPurchases.instance.usesChinaPay) {
      return product.displayTitle(l10n, preferDuration: true);
    }
    if (product.isLifetime) return l10n.productPlanLifetime;
    if (product.isMonthly) return l10n.productPlanMonthly;
    if (product.isSingleYearAnnual) return l10n.productPlanAnnual;
    if (product.isAnnual) {
      final parts = product.subscriptionPeriodParts;
      // 多年档（如 3 年）保留具体年数
      if (parts != null && parts.$2 == Unit.year && parts.$1 > 1) {
        return l10n.productTitleYears(parts.$1);
      }
      return l10n.productPlanAnnual;
    }
    return product.displayTitle(l10n);
  }

  String? _badgeText(AppLocalizations l10n) {
    if (product.isLifetime) return l10n.productBadgeLifetime;
    if (showBestValueBadge && savePercent != null && savePercent! > 0) {
      return l10n.productBadgeBestValue(savePercent!);
    }
    return null;
  }

  String? _subtitleText(AppLocalizations l10n) {
    final chinaPay = AppPurchases.instance.usesChinaPay;
    if (product.isLifetime) return l10n.productSubtitleOneTime;
    if (product.isAnnual) {
      final perMonth = _pricePerMonthString();
      if (perMonth == null) {
        return chinaPay ? null : l10n.productSubtitleAutoRenew;
      }
      final labeled = l10n.productPricePerMonth(perMonth);
      if (chinaPay) return labeled;
      return '$labeled · ${l10n.productSubtitleAutoRenew}';
    }
    if (product.isMonthly) {
      return chinaPay ? null : l10n.productSubtitleAutoRenew;
    }
    return null;
  }

  /// 用年费推算月均价，并尽量保留原币种符号格式
  String? _pricePerMonthString() {
    if (product.price <= 0) return null;
    final parts = product.subscriptionPeriodParts;
    final months = parts != null && parts.$2 == Unit.year ? parts.$1 * 12 : 12;
    final monthly = product.price / months;
    final formatted = monthly >= 10
        ? monthly.toStringAsFixed(0)
        : monthly.toStringAsFixed(2);
    final match = RegExp(r'[\d.,]+').firstMatch(product.priceString);
    if (match == null) return formatted;
    return product.priceString.replaceFirst(match.group(0)!, formatted);
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.isSelected,
    required this.accent,
    required this.outline,
  });

  final bool isSelected;
  final Color accent;
  final Color outline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Durations.short4,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? accent : Colors.transparent,
        border: Border.all(
          color: isSelected ? accent : outline,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
