import 'package:flutter/material.dart';

const kMinAppCardHeaderHeight = 44.0;
const kAppCardMargin = EdgeInsets.symmetric(
  vertical: 8,
  horizontal: 16,
);

class AppCard extends StatelessWidget {
  const AppCard({
    required this.header,
    required this.content,
    super.key,
    this.footer,
    this.padding,
    this.margin,
  });

  factory AppCard.title({
    required Widget content,
    required String title,
    TextStyle? titleTextStyle,
    String? subtitle,
    TextStyle? subtitleTextStyle,
    Widget? trailing,
    Widget? footer,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Key? key,
  }) {
    return AppCard(
      key: key,
      content: content,
      header: SizedBox(
        height: kMinAppCardHeaderHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            // vertical: 12,
            horizontal: 16,
          ),
          child: Row(
            children: [
              Text(title, style: titleTextStyle),
              if (subtitle != null) ...[
                Text(' | ', style: titleTextStyle),
                Text(subtitle, style: subtitleTextStyle),
              ],
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
      footer: footer,
      padding: padding,
      margin: margin,
    );
  }

  final Widget header;
  final Widget content;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleSmall = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.bold,
    );
    return Container(
      margin: margin ?? kAppCardMargin,
      decoration: BoxDecoration(
        border: Border.all(
          strokeAlign: 1,
          color: theme.colorScheme.inverseSurface,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleSmall != null)
            DefaultTextStyle(style: titleSmall, child: header)
          else
            header,
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  strokeAlign: 1,
                  color: theme.colorScheme.inverseSurface,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surfaceContainerLowest,
              ),
              clipBehavior: Clip.hardEdge,
              child: content,
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}
