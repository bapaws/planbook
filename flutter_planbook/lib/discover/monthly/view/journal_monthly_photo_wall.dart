import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/planbook_api.dart';

class JournalMonthlyPhotoWall extends StatelessWidget {
  const JournalMonthlyPhotoWall({
    required this.images,
    super.key,
  });

  final List<NoteImageEntity> images;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (images.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noMonthPhotos,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AppNetworkImage(
            url: image.image,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      },
    );
  }
}
