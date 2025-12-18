import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

class JournalNoteCoverView extends StatelessWidget {
  const JournalNoteCoverView({
    required this.coverImage,
    this.width = 100,
    this.height = 100,
    super.key,
  });

  final String? coverImage;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📷 ${context.l10n.cover}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Divider(
          color: Theme.of(context).colorScheme.outlineVariant,
          height: 16,
          thickness: 1,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AppNetworkImage(
            url: coverImage,
            width: width,
            height: height,
          ),
        ),
      ],
    );
  }
}
