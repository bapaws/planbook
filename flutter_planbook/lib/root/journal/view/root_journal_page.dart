import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/journal/bloc/root_journal_bloc.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/planbook_core.dart';

@RoutePage()
class RootJournalPage extends StatelessWidget {
  const RootJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RootJournalBloc(),
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
  @override
  void initState() {
    super.initState();
    // _controller.addListener(() {
    //   setState(() {});
    // });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final pageWidth = math.min(screenSize.width, screenSize.height) - 32;
    final pageHeight = pageWidth / 296 * 210;
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: Column(
        children: [
          // Row(
          //   children: [
          //     CupertinoButton(
          //       onPressed: _controller.previousPage,
          //       child: const Icon(FontAwesomeIcons.chevronLeft),
          //     ),
          //     CupertinoButton(
          //       onPressed: _controller.nextPage,
          //       child: const Icon(FontAwesomeIcons.chevronRight),
          //     ),
          //   ],
          // ),
          Center(
            child: SizedBox(
              height: pageHeight + 32,
              child: FlipPageView(
                itemsCount: 100,
                initialPage: 10,
                itemBuilder: (context, index) => Container(
                  width: pageWidth,
                  height: pageHeight,
                  decoration: BoxDecoration(
                    color: Colors.primaries[index % Colors.primaries.length],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Item $index',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
