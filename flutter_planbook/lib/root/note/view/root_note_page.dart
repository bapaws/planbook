import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_calendar_view.dart';
import 'package:flutter_planbook/app/view/app_tag_icon.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/note/gallery/bloc/note_gallery_bloc.dart';
import 'package:flutter_planbook/note/timeline/bloc/note_timeline_bloc.dart';
import 'package:flutter_planbook/root/note/bloc/root_note_bloc.dart';
import 'package:flutter_planbook/root/note/view/root_note_drawer.dart';
import 'package:flutter_planbook/root/note/view/root_note_gallery_title_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';

@RoutePage()
class RootNotePage extends StatelessWidget {
  const RootNotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RootNoteBloc(),
        ),
        BlocProvider(
          create: (context) => NoteTimelineBloc(),
        ),
        BlocProvider(
          create: (context) => NoteGalleryBloc(
            notesRepository: context.read(),
          )..add(NoteGalleryRequested(date: Jiffy.now())),
        ),
      ],
      child: AutoTabsRouter(
        routes: [
          NoteTimelineRoute(),
          const NoteWrittenRoute(),
          const NoteTaskRoute(),
          const NoteGalleryRoute(),
          const NoteTagRoute(),
        ],
        builder: (context, child) => _RootNotePage(child: child),
      ),
    );
  }
}

class _RootNotePage extends StatelessWidget {
  _RootNotePage({required this.child});

  final Widget child;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final activeIndex = context.tabsRouter.activeIndex;
    final tab = RootNoteTab.values[activeIndex];
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const RootNoteDrawer(),
      drawerEdgeDragWidth: 72,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: CupertinoButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          child: const Icon(FontAwesomeIcons.bars),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: BlocBuilder<RootNoteBloc, RootNoteState>(
          builder: (context, state) => AnimatedSwitcher(
            duration: Durations.medium1,
            child: switch (tab) {
              RootNoteTab.gallery =>
                BlocBuilder<NoteGalleryBloc, NoteGalleryState>(
                  builder: (context, state) => RootNoteGalleryTitleView(
                    date: state.date,
                    isCalendarExpanded: state.isCalendarExpanded,
                    onDateSelected: (date) {
                      context.read<NoteGalleryBloc>().add(
                        NoteGalleryDateSelected(date: date),
                      );
                    },
                    onCalendarToggled: () {
                      context.read<NoteGalleryBloc>().add(
                        const NoteGalleryCalendarToggled(),
                      );
                    },
                  ),
                ),
              RootNoteTab.tag => Row(
                children: [
                  AppTagIcon.fromTagEntity(state.tag!),
                  const SizedBox(width: 4),
                  Text(state.tag!.fullName),
                ],
              ),
              _ => BlocBuilder<NoteTimelineBloc, NoteTimelineState>(
                buildWhen: (previous, current) =>
                    previous.date != current.date ||
                    previous.calendarFormat != current.calendarFormat,
                builder: (context, state) {
                  return AppCalendarDateView(
                    date: state.date,
                    calendarFormat: state.calendarFormat,
                    onDateSelected: (date) {
                      context.read<NoteTimelineBloc>().add(
                        NoteTimelineDateSelected(date: date),
                      );
                    },
                    onCalendarFormatChanged: (calendarFormat) {
                      context.read<NoteTimelineBloc>().add(
                        NoteTimelineCalendarFormatChanged(
                          calendarFormat: calendarFormat,
                        ),
                      );
                    },
                  );
                },
              ),
            },
          ),
        ),
      ),
      body: child,
    );
  }
}
