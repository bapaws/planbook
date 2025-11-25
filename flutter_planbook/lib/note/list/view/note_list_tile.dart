import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/app/view/app_tag_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';

class NoteListTile extends StatelessWidget {
  const NoteListTile({
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(
                FontAwesomeIcons.circle,
                size: 16,
              ),
              const SizedBox(width: 16),
              Text(
                note.createdAt.toLocal().jm,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // if (note.activity != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                sizeStyle: CupertinoButtonSize.small,
                onPressed: () {},
                child: const Icon(FontAwesomeIcons.link, size: 14),
              ),
            ],
          ),
        ),
        IntrinsicHeight(
          child: Row(
            children: [
              VerticalDivider(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (note.title.isNotEmpty)
                      Text(
                        note.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    if (note.content != null)
                      Text(
                        note.content ?? '',
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
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
    final screenWidth = MediaQuery.of(context).size.width;
    const crossAxisCount = 3;
    const spacing = 4.0;
    final availableWidth =
        screenWidth - 16 * 2 - 16 - 16; // padding + divider + spacing
    final imageSize =
        ((availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount)
            .floorToDouble();
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
                    SizedBox(
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
