import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_bookshelf.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_flight.dart';
import 'package:flutter_planbook/discover/bookshelf/view/root_stack_router_scope.dart';
import 'package:flutter_planbook/discover/focus/bloc/discover_focus_bloc.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_cover.dart';
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
class DiscoverBrowsePage extends StatelessWidget {
  const DiscoverBrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        DiscoverJournalRoute(),
        DiscoverFocusRoute(),
        DiscoverSummaryRoute(),
      ],
      builder: (context, child) => _DiscoverBrowsePage(child: child),
    );
  }
}

class _DiscoverBrowsePage extends StatefulWidget {
  const _DiscoverBrowsePage({required this.child});

  final Widget child;

  @override
  State<_DiscoverBrowsePage> createState() => _DiscoverBrowsePageState();
}

class _DiscoverBrowsePageState extends State<_DiscoverBrowsePage> {
  final _shelfKey = GlobalKey<NotebookBookshelfState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _openNotebook(NotebookKind kind) async {
    // 日记本是 PRO 功能，非会员直接进入会员页。
    if (kind == NotebookKind.diary &&
        !context.read<AppPurchasesBloc>().isPremium) {
      await context.router.push(const AppPurchasesRoute());
      return;
    }
    final rect = _shelfKey.currentState?.coverGlobalRect(kind);
    if (rect == null || !mounted) return;
    final bloc = context.read<RootDiscoverBloc>();
    NotebookLaunch.request = NotebookLaunchRequest(
      sourceRect: rect,
      coverRectOf: () => _shelfKey.currentState?.coverGlobalRect(kind),
      onClosed: () {
        if (mounted) bloc.add(const RootDiscoverNotebookChanged(null));
      },
    );
    try {
      await context.router.push(NotebookReaderRoute(kind: kind));
    } on Object {
      // 路由没建起来时，别把这次起点留给下一次打开。
      NotebookLaunch.take();
      if (mounted) bloc.add(const RootDiscoverNotebookChanged(null));
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = context.tabsRouter.activeIndex;
    final tab = RootDiscoverTab.values[activeIndex];
    final route = ModalRoute.of(context);
    final secondary = route?.secondaryAnimation ?? kAlwaysDismissedAnimation;
    return RootStackRouterScope(
      child: AnimatedBuilder(
        animation: secondary,
        builder: (context, child) {
          final obscured =
              route != null && (!route.isCurrent || secondary.value > 0.01);
          return AppScaffold(
            scaffoldKey: _scaffoldKey,
            drawer: const RootDiscoverDrawer(),
            drawerEdgeDragWidth: 72,
            backgroundColor: Colors.transparent,
            showBackground: false,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Opacity(
                opacity: 1 - notebookFlightProgress(secondary.value),
                child: IgnorePointer(
                  ignoring: obscured,
                  child: AppBar(
                    forceMaterialTransparency: true,
                    leading: CupertinoButton(
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const FaIcon(FontAwesomeIcons.bars),
                    ),
                    automaticallyImplyLeading: false,
                    titleSpacing: 0,
                    title: AnimatedSwitcher(
                      duration: Durations.medium1,
                      child: switch (tab) {
                        RootDiscoverTab.journal => Text(context.l10n.notebooks),
                        RootDiscoverTab.focusMindMap =>
                          BlocBuilder<DiscoverFocusBloc, DiscoverFocusState>(
                            builder: (context, state) =>
                                RootNoteGalleryTitleView(
                                  date: state.date,
                                  isCalendarExpanded: state.isCalendarExpanded,
                                  onDateSelected: (date) =>
                                      context.read<DiscoverFocusBloc>().add(
                                        DiscoverFocusCalendarDateSelected(
                                          date: date,
                                        ),
                                      ),
                                  onCalendarToggled: () =>
                                      context.read<DiscoverFocusBloc>().add(
                                        const DiscoverFocusCalendarExpanded(),
                                      ),
                                ),
                          ),
                        RootDiscoverTab.summaryMindMap =>
                          BlocBuilder<DiscoverSummaryBloc, DiscoverFocusState>(
                            builder: (context, state) =>
                                RootNoteGalleryTitleView(
                                  date: state.date,
                                  isCalendarExpanded: state.isCalendarExpanded,
                                  onDateSelected: (date) =>
                                      context.read<DiscoverSummaryBloc>().add(
                                        DiscoverFocusCalendarDateSelected(
                                          date: date,
                                        ),
                                      ),
                                  onCalendarToggled: () =>
                                      context.read<DiscoverSummaryBloc>().add(
                                        const DiscoverFocusCalendarExpanded(),
                                      ),
                                ),
                          ),
                      },
                    ),
                    actions: tab == RootDiscoverTab.journal
                        ? const []
                        : [
                            PullDownButton(
                              itemBuilder: (context) => [
                                PullDownMenuItem(
                                  icon: FontAwesomeIcons.calendarMinus.data,
                                  title: context.l10n.thisWeek,
                                  onTap: () {
                                    context.read<DiscoverFocusBloc>().add(
                                      DiscoverFocusRequested(date: Jiffy.now()),
                                    );
                                  },
                                ),
                              ],
                              buttonBuilder: (context, showMenu) =>
                                  CupertinoButton(
                                    onPressed: showMenu,
                                    child: const FaIcon(
                                      FontAwesomeIcons.ellipsis,
                                    ),
                                  ),
                            ),
                          ],
                  ),
                ),
              ),
            ),
            body: ExcludeSemantics(
              excluding: obscured,
              child: child,
            ),
          );
        },
        child: tab == RootDiscoverTab.journal
            ? NotebookBookshelf(
                key: _shelfKey,
                onSelected: (_) {},
                onOpen: _openNotebook,
                plannerCoverBuilder: (context) =>
                    BlocBuilder<DiscoverJournalBloc, DiscoverJournalState>(
                      builder: (context, state) => JournalCover(
                        year: state.date.year,
                        backgroundImage:
                            state.coverBackgroundImage ??
                            'assets/images/cover.jpg',
                        colorScheme: state.coverColorScheme,
                      ),
                    ),
                plannerBackCoverBuilder: (context) =>
                    BlocBuilder<DiscoverJournalBloc, DiscoverJournalState>(
                      builder: (context, state) => JournalBackCover(
                        year: state.date.year,
                        backgroundImage:
                            state.coverBackgroundImage ??
                            'assets/images/cover.jpg',
                        colorScheme: state.coverColorScheme,
                      ),
                    ),
              )
            : widget.child,
      ),
    );
  }
}
