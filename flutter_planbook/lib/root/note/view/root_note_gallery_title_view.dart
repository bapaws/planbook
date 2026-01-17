import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';

class RootNoteGalleryTitleView extends StatelessWidget {
  const RootNoteGalleryTitleView({
    required this.date,
    required this.isCalendarExpanded,
    required this.onDateSelected,
    required this.onCalendarToggled,
    super.key,
  });

  final Jiffy date;
  final bool isCalendarExpanded;
  final VoidCallback onCalendarToggled;
  final ValueChanged<Jiffy> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () {
            onDateSelected(Jiffy.now());
          },
          child: Text(
            date.format(pattern: 'y'),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size.square(
            kMinInteractiveDimensionCupertino,
          ),
          onPressed: onCalendarToggled,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(
                kMinInteractiveDimension,
              ),
            ),
            child: AnimatedRotation(
              turns: isCalendarExpanded ? 0.25 : 0,
              duration: Durations.medium1,
              child: Icon(
                FontAwesomeIcons.chevronRight,
                size: 12,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
