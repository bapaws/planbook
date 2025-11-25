import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_tag_icon.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:pull_down_button/pull_down_button.dart';

class TagListTile extends StatelessWidget {
  const TagListTile({
    required this.tag,
    this.isSelected,
    this.onSelected,
    this.onDeleted,
    this.onEdited,
    super.key,
  });

  final TagEntity tag;
  final bool? isSelected;
  final VoidCallback? onSelected;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdited;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.brightness == Brightness.dark
        ? tag.dark
        : tag.light;
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          icon: FontAwesomeIcons.penToSquare,
          title: context.l10n.edit,
          onTap: onEdited,
        ),
        const PullDownMenuDivider.large(),
        PullDownMenuItem(
          icon: FontAwesomeIcons.trash,
          title: context.l10n.delete,
          isDestructive: true,
          onTap: onDeleted,
        ),
      ],
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size.square(kMinInteractiveDimension),
        sizeStyle: CupertinoButtonSize.medium,
        onLongPress: showMenu,
        onPressed: onSelected,
        child: Row(
          children: [
            SizedBox(width: 24 * tag.level.toDouble()),
            AppTagIcon.fromTagEntity(tag, size: 24),
            const SizedBox(width: 8),
            Text(
              tag.name,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme?.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected != null)
              Icon(
                isSelected!
                    ? FontAwesomeIcons.solidCircleCheck
                    : FontAwesomeIcons.circle,
                size: 18,
                color: colorScheme?.primary,
              )
            else
              const CupertinoListTileChevron(),
          ],
        ),
      ),
    );
  }
}
