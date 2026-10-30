import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:shimmer/shimmer.dart';

class AppProView extends StatelessWidget {
  const AppProView({super.key, this.style, this.animate = true});

  final TextStyle? style;

  /// 书架等常驻按钮关掉循环闪烁，避免动画无法结束。
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = Text(
      'PRO',
      style:
          style ??
          theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.tertiary,
            fontWeight: FontWeight.bold,
          ),
    );
    if (!animate) return label;
    return Shimmer(
      gradient: const LinearGradient(
        colors: [
          Colors.red,
          Colors.blue,
          Colors.red,
        ],
      ),
      child: label,
    );
  }
}

class AppProButton extends StatelessWidget {
  const AppProButton({super.key, this.style, this.isPremium = false});

  final bool isPremium;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoButton(
      minimumSize: Size.zero,
      onPressed: () {
        context.router.push(const AppPurchasesRoute());
      },
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      color: isPremium
          ? theme.colorScheme.tertiaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(
        6,
      ),
      child: isPremium
          ? AppProView(
              style: style?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            )
          : Text(
              'PRO',
              style:
                  style?.copyWith(
                    color: theme.colorScheme.outlineVariant,
                    fontWeight: FontWeight.bold,
                  ) ??
                  theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.outlineVariant,
                    fontWeight: FontWeight.bold,
                  ),
            ),
    );
  }
}
