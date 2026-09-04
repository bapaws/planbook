import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    this.foregroundColor = Colors.white,
    this.backgroundColor = Colors.greenAccent,
    this.size = 24,
    super.key,
  });

  final IconData icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      // FA 11 需用 FaIcon，避免 Material Icon 方形裁切。
      child: Center(
        child: FaIcon(
          FaIconData(icon),
          size: size / 2,
          color: foregroundColor,
        ),
      ),
    );
  }
}
