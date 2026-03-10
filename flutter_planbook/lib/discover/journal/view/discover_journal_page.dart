import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_date_change_view.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_flip_view.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_horizontal_view.dart';
import 'package:flutter_planbook/note/gallery/view/note_gallery_calendar_view.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_core/view/flip_page_view.dart';

@RoutePage()
class DiscoverJournalPage extends StatefulWidget {
  const DiscoverJournalPage({super.key});

  @override
  State<DiscoverJournalPage> createState() => _DiscoverJournalPageState();
}

class _DiscoverJournalPageState extends State<DiscoverJournalPage> {
  late final FlipPageController _controller;

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
    final theme = Theme.of(context);
    final query = MediaQuery.of(context);
    return Column(
      children: [
        BlocSelector<DiscoverJournalBloc, DiscoverJournalState, bool>(
          selector: (state) => state.isCalendarExpanded,
          builder: (context, isCalendarExpanded) {
            return AnimatedSwitcher(
              duration: Durations.medium1,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  child: child,
                ),
              ),
              child: isCalendarExpanded
                  ? NoteGalleryCalendarView(
                      date: context.read<DiscoverJournalBloc>().state.date,
                      onDateSelected: (date) {
                        context.read<DiscoverJournalBloc>().add(
                          DiscoverJournalDateChanged(date: date),
                        );
                      },
                    )
                  : null,
            );
          },
        ),
        const Spacer(),
        BlocSelector<DiscoverJournalBloc, DiscoverJournalState, Jiffy>(
          selector: (state) => state.date,
          builder: (context, date) {
            return DiscoverJournalDateChangeView(
              date: date,
              onDateChanged: (date) {
                context.read<DiscoverJournalBloc>().add(
                  DiscoverJournalDateChanged(date: date),
                );
              },
            );
          },
        ),
        const Spacer(),
        AnimatedSwitcher(
          duration: Durations.medium1,
          child:
              BlocSelector<
                DiscoverJournalBloc,
                DiscoverJournalState,
                DiscoverJournalViewType
              >(
                selector: (state) => state.viewType,
                builder: (context, viewType) => switch (viewType) {
                  DiscoverJournalViewType.flip => DiscoverJournalFlipView(
                    controller: _controller,
                  ),
                  DiscoverJournalViewType.horizontal =>
                    DiscoverJournalHorizontalView(
                      initialDate: context
                          .read<DiscoverJournalBloc>()
                          .state
                          .date,
                    ),
                },
              ),
        ),
        const Spacer(flex: 3),
        SizedBox(height: query.padding.bottom + kRootBottomBarHeight),
      ],
    );
  }
}
