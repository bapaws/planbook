import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';

class AppTagView extends StatelessWidget {
  const AppTagView({required this.tag, this.onTap, super.key});

  final TagEntity tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.brightness == Brightness.dark
        ? tag.dark
        : tag.light;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: colorScheme?.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.hashtag,
              size: 9,
              color: colorScheme?.primary,
            ),
            const SizedBox(width: 2),
            Text(
              tag.fullName,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme?.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
