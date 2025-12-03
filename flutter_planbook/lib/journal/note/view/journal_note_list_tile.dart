import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/app/view/app_tag_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';

class JournalNoteListTile extends StatelessWidget {
  const JournalNoteListTile({
    required this.note,
    super.key,
  });

  final NoteEntity note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(
                FontAwesomeIcons.circle,
                size: 10,
              ),
              const SizedBox(width: 6),
              Text(
                note.createdAt.toLocal().jm,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        IntrinsicHeight(
          child: Row(
            children: [
              VerticalDivider(
                thickness: 1,
                width: 10,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  spacing: 4,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (note.title.isNotEmpty)
                      Text(
                        note.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    if (note.content != null)
                      Text(
                        note.content ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (note.images.isNotEmpty)
                      _buildImages(context, note.images),
                    if (note.tags.isNotEmpty) _buildTags(context, note.tags),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImages(BuildContext context, List<String> images) {
    const crossAxisCount = 3;
    const spacing = 2.0;
    const imageSize = 52.0;
    final imageCount = images.length > 9 ? 9 : images.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < (imageCount / crossAxisCount).ceil(); row++)
          Padding(
            padding: EdgeInsets.only(
              bottom: row < (imageCount / crossAxisCount).ceil() - 1
                  ? spacing
                  : 0,
            ),
            child: Row(
              children: [
                for (int col = 0; col < crossAxisCount; col++)
                  if (row * crossAxisCount + col < imageCount)
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: col < crossAxisCount - 1 ? spacing : 0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            8,
                          ),
                          child: AppNetworkImage(
                            url: images[row * crossAxisCount + col],
                            width: imageSize,
                            height: imageSize,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: imageSize,
                      height: imageSize,
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTags(BuildContext context, List<TagEntity> tags) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final tag in tags) AppTagView(tag: tag, onTap: () {}),
      ],
    );
  }
}
