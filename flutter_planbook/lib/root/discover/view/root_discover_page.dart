import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/focus/bloc/discover_focus_bloc.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/discover/summary/bloc/discover_summary_bloc.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:jiffy/jiffy.dart';

@RoutePage()
class RootDiscoverPage extends StatelessWidget {
  const RootDiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final now = Jiffy.now();
            return DiscoverJournalBloc(
              now: now,
              usersRepository: context.read(),
            )..add(DiscoverJournalRequested(year: now.year));
          },
        ),
        BlocProvider(
          create: (context) {
            final state = context.read<RootDiscoverBloc>().state;
            return DiscoverFocusBloc(notesRepository: context.read())..add(
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
            return DiscoverSummaryBloc(notesRepository: context.read())..add(
              DiscoverFocusRequested(
                date: state.summaryDate,
                noteType: state.summaryType,
              ),
            );
          },
        ),
      ],
      child: const AutoRouter(),
    );
  }
}
