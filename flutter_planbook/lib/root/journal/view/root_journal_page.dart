import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/journal/day/view/journal_day_page.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/root/journal/bloc/root_journal_bloc.dart';
import 'package:flutter_planbook/root/journal/view/root_journal_drawer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/planbook_core.dart';

@RoutePage()
class RootJournalPage extends StatelessWidget {
  const RootJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RootJournalBloc(
        tasksRepository: context.read(),
        notesRepository: context.read(),
        now: Jiffy.now(),
      )..add(const RootJournalRequested()),
      child: const _RootJournalPage(),
    );
  }
}

class _RootJournalPage extends StatefulWidget {
  const _RootJournalPage();

  @override
  State<_RootJournalPage> createState() => _RootJournalPageState();
}

class _RootJournalPageState extends State<_RootJournalPage> {
  late final FlipPageController _controller;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    final now = Jiffy.now();
    final startOfYear = now.startOf(Unit.year);
    final page = now.diff(startOfYear, unit: Unit.day).toInt();
    _controller = FlipPageController(initialPage: page);
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final screenSize = MediaQuery.of(context).size;
    final pageWidth = math.min(screenSize.width, screenSize.height) - 32;
    final scale = pageWidth / kJournalPageWidth;
    final pageHeight = kJournalPageHeight * scale;
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const RootJournalDrawer(),
      drawerEdgeDragWidth: 96,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: CupertinoButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          child: const Icon(FontAwesomeIcons.bars),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: BlocBuilder<RootJournalBloc, RootJournalState>(
          buildWhen: (previous, current) => previous.year != current.year,
          builder: (context, state) => AnimatedSwitcher(
            duration: Durations.medium1,
            child: Text(state.year.toString()),
          ),
        ),
      ),
      body: Center(
        child: BlocBuilder<RootJournalBloc, RootJournalState>(
          builder: (context, state) {
            final startOfYear = Jiffy.parseFromList([state.year]);
            var initialPage = 0;
            final now = Jiffy.now();
            if (now.year == state.year) {
              initialPage = now.diff(startOfYear, unit: Unit.day).toInt();
            }

            return Container(
              width: pageWidth + 32,
              height: pageHeight + 32,
              margin: EdgeInsets.only(
                bottom: query.padding.bottom + kRootBottomBarHeight,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: FlipPageView(
                key: ValueKey(state.year),
                initialPage: initialPage,
                itemsCount: state.days,
                // controller: _controller,
                itemBuilder: (context, index) => FittedBox(
                  key: ValueKey(index),
                  child: JournalDayPage(
                    date: startOfYear.add(days: index),
                    scale: scale,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
