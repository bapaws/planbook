import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/summary/bloc/discover_summary_bloc.dart';

@RoutePage()
class DiscoverSummaryPage extends StatelessWidget {
  const DiscoverSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DiscoverSummaryBloc(),
      child: const _DiscoverSummaryPage(),
    );
  }
}

class _DiscoverSummaryPage extends StatelessWidget {
  const _DiscoverSummaryPage();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
