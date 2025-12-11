import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NavigationBarBackButton extends StatelessWidget {
  const NavigationBarBackButton({this.color, this.onPressed, super.key});

  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBarBackButton(
      color: color,
      onPressed: onPressed,
      previousPageTitle: '',
    );
  }
}

class NavigationBarCloseButton extends StatelessWidget {
  const NavigationBarCloseButton({this.color, this.onPressed, super.key});

  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final actionTextStyle = CupertinoTheme.of(
      context,
    ).textTheme.navActionTextStyle;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(kToolbarHeight, kToolbarHeight),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      child: Icon(
        CupertinoIcons.xmark,
        color: color ?? actionTextStyle.color,
        size: 24,
      ),
    );
  }
}
