import 'package:flutter_planbook/discover/focus/bloc/discover_focus_bloc.dart';

class DiscoverSummaryBloc extends DiscoverFocusBloc {
  DiscoverSummaryBloc({
    required super.notesRepository,
    super.isSummary = true,
  });
}
