import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/note/gallery/bloc/note_gallery_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';

class RootNoteGalleryTitleView extends StatelessWidget {
  const RootNoteGalleryTitleView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () {
            context.read<NoteGalleryBloc>().add(
              NoteGalleryDateSelected(date: Jiffy.now()),
            );
          },
          child: BlocSelector<NoteGalleryBloc, NoteGalleryState, Jiffy>(
            selector: (state) => state.date,
            builder: (context, date) => Text(
              date.format(pattern: 'y'),
              style: theme.appBarTheme.titleTextStyle,
            ),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size.square(
            kMinInteractiveDimensionCupertino,
          ),
          onPressed: () {
            context.read<NoteGalleryBloc>().add(
              const NoteGalleryCalendarToggled(),
            );
          },
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(
                kMinInteractiveDimension,
              ),
            ),
            child: BlocSelector<NoteGalleryBloc, NoteGalleryState, bool>(
              selector: (state) => state.isCalendarExpanded,
              builder: (context, isCalendarExpanded) => AnimatedRotation(
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
        ),
      ],
    );
  }
}
