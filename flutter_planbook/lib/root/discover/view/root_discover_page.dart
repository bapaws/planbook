import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/discover/focus/bloc/discover_focus_bloc.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/discover/summary/bloc/discover_summary_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/discover/model/root_discover_tab.dart';
import 'package:flutter_planbook/root/discover/view/root_discover_drawer.dart';
import 'package:flutter_planbook/root/note/view/root_note_gallery_title_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:pull_down_button/pull_down_button.dart';

@RoutePage()
class RootDiscoverPage extends StatelessWidget {
  const RootDiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DiscoverJournalBloc(
            tasksRepository: context.read(),
            notesRepository: context.read(),
            now: Jiffy.now(),
          ),
        ),
        BlocProvider(
          create: (context) {
            final state = context.read<RootDiscoverBloc>().state;
            return DiscoverFocusBloc(
              notesRepository: context.read(),
            )..add(
              DiscoverFocusRequested(
                date: state.focusDate,
                noteType: state.focusType,
              ),
            );
          },
        ),
        BlocProvider(
          create: (context) {
            final state = context.read<RootDiscoverBloc>().state;
            return DiscoverSummaryBloc(
              notesRepository: context.read(),
            )..add(
              DiscoverFocusRequested(
                date: state.summaryDate,
                noteType: state.summaryType,
              ),
            );
          },
        ),
      ],
      child: AutoTabsRouter(
        routes: const [
          DiscoverJournalRoute(),
          DiscoverFocusRoute(),
          DiscoverSummaryRoute(),
        ],
        builder: (context, child) => _RootDiscoverPage(child: child),
      ),
    );
  }
}

class _RootDiscoverPage extends StatelessWidget {
  _RootDiscoverPage({required this.child});

  final Widget child;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final activeIndex = context.tabsRouter.activeIndex;
    final tab = RootDiscoverTab.values[activeIndex];
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const RootDiscoverDrawer(),
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
        title: AnimatedSwitcher(
          duration: Durations.medium1,
          child: switch (tab) {
            RootDiscoverTab.journal =>
              BlocBuilder<DiscoverJournalBloc, DiscoverJournalState>(
                builder: (context, state) => RootNoteGalleryTitleView(
                  date: state.date,
                  isCalendarExpanded: state.isCalendarExpanded,
                  onDateSelected: (date) =>
                      context.read<DiscoverJournalBloc>().add(
                        JournalHomeYearChanged(date: date),
                      ),
                  onCalendarToggled: () =>
                      context.read<DiscoverJournalBloc>().add(
                        const JournalHomeCalendarToggled(),
                      ),
                ),
              ),
            RootDiscoverTab.focusMindMap =>
              BlocBuilder<DiscoverFocusBloc, DiscoverFocusState>(
                builder: (context, state) => RootNoteGalleryTitleView(
                  date: state.date,
                  isCalendarExpanded: state.isCalendarExpanded,
                  onDateSelected: (date) =>
                      context.read<DiscoverFocusBloc>().add(
                        DiscoverFocusCalendarDateSelected(date: date),
                      ),
                  onCalendarToggled: () =>
                      context.read<DiscoverFocusBloc>().add(
                        const DiscoverFocusCalendarExpanded(),
                      ),
                ),
              ),
            RootDiscoverTab.summaryMindMap =>
              BlocBuilder<DiscoverSummaryBloc, DiscoverFocusState>(
                builder: (context, state) => RootNoteGalleryTitleView(
                  date: state.date,
                  isCalendarExpanded: state.isCalendarExpanded,
                  onDateSelected: (date) =>
                      context.read<DiscoverSummaryBloc>().add(
                        DiscoverFocusCalendarDateSelected(date: date),
                      ),
                  onCalendarToggled: () =>
                      context.read<DiscoverSummaryBloc>().add(
                        const DiscoverFocusCalendarExpanded(),
                      ),
                ),
              ),
          },
        ),
        actions: [
          if (tab == RootDiscoverTab.journal)
            PullDownButton(
              itemBuilder: (context) => switch (tab) {
                RootDiscoverTab.journal => [
                  PullDownMenuItem(
                    icon: FontAwesomeIcons.play,
                    title: context.l10n.autoPlay,
                    onTap: () {
                      context.read<RootDiscoverBloc>().add(
                        const RootDiscoverAutoPlay(),
                      );
                    },
                  ),
                ],
                RootDiscoverTab.focusMindMap ||
                RootDiscoverTab.summaryMindMap => [
                  PullDownMenuItem(
                    icon: FontAwesomeIcons.calendarMinus,
                    title: context.l10n.thisWeek,
                    onTap: () {
                      context.read<DiscoverFocusBloc>().add(
                        DiscoverFocusRequested(date: Jiffy.now()),
                      );
                      // context.read<DiscoverFocusBloc>().add(
                      //   const DiscoverFocusAllNodesExpanded(),
                      // );
                    },
                  ),
                ],
              },
              buttonBuilder: (context, showMenu) => CupertinoButton(
                onPressed: showMenu,
                child: const Icon(FontAwesomeIcons.ellipsis),
              ),
            ),
        ],
      ),
      body: child,
    );
  }
}
