import 'package:flutter/cupertino.dart';

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
