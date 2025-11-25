import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/tag_entity.dart';

class AppTagIcon extends StatelessWidget {
  const AppTagIcon({
    this.foregroundColor = Colors.white,
    this.backgroundColor = Colors.greenAccent,
    this.size = 28,
    super.key,
  });

  factory AppTagIcon.fromTagEntity(TagEntity tag, {double size = 28}) {
    return AppTagIcon(
      foregroundColor: tag.light?.primary,
      backgroundColor: tag.light?.primaryContainer,
      size: size,
    );
  }

  final Color? foregroundColor;
  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppIcon(
      FontAwesomeIcons.hashtag,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      size: size,
    );
  }
}
