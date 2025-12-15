import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_calendar_view.dart';
import 'package:flutter_planbook/app/view/app_tag_icon.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/note/gallery/view/note_gallery_page.dart';
import 'package:flutter_planbook/note/tag/view/note_tag_page.dart';
import 'package:flutter_planbook/note/timeline/bloc/note_timeline_bloc.dart';
import 'package:flutter_planbook/note/timeline/view/note_timeline_page.dart';
import 'package:flutter_planbook/root/note/bloc/root_note_bloc.dart';
import 'package:flutter_planbook/root/note/view/root_note_drawer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      ],
      child: _RootNotePage(),
    );
  }
}

class _RootNotePage extends StatelessWidget {
  _RootNotePage();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const RootNoteDrawer(),
      drawerEdgeDragWidth: 120,
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
            child: switch (state.tab) {
              RootNoteTab.gallery => Text(state.galleryDate.year.toString()),
              RootNoteTab.timeline =>
                BlocBuilder<NoteTimelineBloc, NoteTimelineState>(
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
              RootNoteTab.tag => Row(
                children: [
                  AppTagIcon.fromTagEntity(state.tag!),
                  const SizedBox(width: 4),
                  Text(state.tag!.fullName),
                ],
              ),
            },
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<RootNoteBloc, RootNoteState>(
      buildWhen: (previous, current) =>
          previous.tab != current.tab || previous.tag != current.tag,
      builder: (context, state) => AnimatedSwitcher(
        duration: Durations.medium1,
        child: switch (state.tab) {
          RootNoteTab.gallery => const NoteGalleryPage(),
          RootNoteTab.timeline => const NoteTimelinePage(),
          RootNoteTab.tag => NoteTagPage(
            key: ValueKey(state.tag!.id),
            tag: state.tag!,
          ),
        },
      ),
    );
  }
}
