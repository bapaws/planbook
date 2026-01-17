import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_decorations.dart';

const kJournalDailyHeaderHeight = 24.0;

/// 手账日报头部组件
class JournalDailyHeader extends StatelessWidget {
  const JournalDailyHeader({
    required this.title,
    this.count,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.titleStyle,
    this.badgeColor,
    this.badgeTextColor,
    this.showDashedLine = true,
    this.dashedLineColor,
    super.key,
  });

  /// 标题文字
  final String title;

  /// 数量（显示在徽章中）
  final int? count;

  /// 装饰图标
  final Widget? icon;

  /// 图标颜色（如果不指定则使用主题色）
  final Color? iconColor;

  /// 图标背景颜色（如果不指定则使用主题色）
  final Color? iconBackgroundColor;

  /// 标题样式（如果不指定则使用默认样式）
  final TextStyle? titleStyle;

  /// 徽章背景颜色（如果不指定则使用主题色）
  final Color? badgeColor;

  /// 徽章文字颜色（如果不指定则使用主题色）
  final Color? badgeTextColor;

  /// 是否显示装饰性虚线
  final bool showDashedLine;

  /// 虚线颜色（如果不指定则使用主题色）
  final Color? dashedLineColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveIconBackgroundColor =
        (iconBackgroundColor ?? theme.colorScheme.primaryContainer).withOpacity(
          0.5,
        );
    final effectiveBadgeColor =
        (badgeColor ?? theme.colorScheme.secondaryContainer).withOpacity(0.6);
    final effectiveBadgeTextColor =
        badgeTextColor ?? theme.colorScheme.onSecondaryContainer;
    final effectiveDashedLineColor =
        dashedLineColor ?? theme.colorScheme.surfaceContainerHighest;

    return Row(
      children: [
        // 装饰图标
        if (icon != null)
          Container(
            width: kJournalDailyHeaderHeight,
            height: kJournalDailyHeaderHeight,
            decoration: BoxDecoration(
              color: effectiveIconBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
        const SizedBox(width: 8),
        // 标题
        Text(
          title,
          style:
              titleStyle ??
              theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(width: 8),
        // 数量徽章
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: effectiveBadgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: effectiveBadgeTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const Spacer(),
        // 装饰性虚线
        if (showDashedLine)
          Expanded(
            flex: 2,
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: DashedLinePainter(
                color: effectiveDashedLineColor,
              ),
            ),
          ),
        Text(
          '✧',
          style: TextStyle(
            fontSize: 21,
            color: effectiveIconColor,
          ),
        ),
        SizedBox(
          width: 16,
          child: CustomPaint(
            size: const Size(double.infinity, 1),
            painter: DashedLinePainter(
              color: effectiveDashedLineColor,
            ),
          ),
        ),
      ],
    );
  }
}
