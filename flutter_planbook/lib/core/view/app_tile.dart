import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTile extends StatelessWidget {
  const AppTile({
    required this.title,
    this.leading,
    super.key,
    this.subtitle,
    this.trailing,
    this.onPressed,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  factory AppTile.text({
    required String title,
    TextStyle? titleStyle,
    Widget? leading,
    String? subtitle,
    TextStyle? subtitleStyle,
    Widget? trailing,
    VoidCallback? onPressed,
    EdgeInsetsGeometry? margin = const EdgeInsets.symmetric(vertical: 6),
    EdgeInsetsGeometry? padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  }) => AppTile(
    leading: leading,
    title: Text(
      title,
      style: titleStyle,
    ),
    subtitle: subtitle != null ? Text(subtitle, style: subtitleStyle) : null,
    trailing: trailing,
    onPressed: onPressed,
    margin: margin,
    padding: padding,
  );

  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Container(
      margin: margin,
      padding: padding,
      constraints: const BoxConstraints(
        minHeight: 56,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
      child: Row(
        spacing: 4,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style:
                    theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ) ??
                    TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                child: title,
              ),
              if (subtitle != null)
                DefaultTextStyle(
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ) ??
                      TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                  child: subtitle!,
                ),
            ],
          ),
          const Spacer(),
          if (trailing != null) trailing!,
          if (onPressed != null) const CupertinoListTileChevron(),
        ],
      ),
    );
    if (onPressed == null) return child;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      // minimumSize: const Size(double.infinity, 56),
      onPressed: onPressed,
      child: child,
    );
  }
}

class AppSliverTile extends StatelessWidget {
  const AppSliverTile({
    required this.leading,
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.onPressed,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final VoidCallback? onPressed;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AppTile.text(
        onPressed: onPressed,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        margin: margin,
        padding: padding,
      ),
    );
  }
}
