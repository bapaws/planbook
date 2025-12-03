import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    super.key,
    this.leading,
    this.trailing = const CupertinoListTileChevron(),
    this.onPressed,
    this.additionalInfo,
    this.subtitle,
    this.padding,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? additionalInfo;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      backgroundColor: Colors.transparent,
      backgroundColorActivated: theme.colorScheme.surfaceContainerHighest,
      leading: leading,
      title: title,
      subtitle: subtitle,
      additionalInfo: additionalInfo,
      trailing: trailing,
      onTap: onPressed,
    );
  }
}
