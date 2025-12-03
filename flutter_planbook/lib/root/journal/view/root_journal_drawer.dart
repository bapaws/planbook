import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/root/journal/bloc/root_journal_bloc.dart';
import 'package:flutter_planbook/root/task/view/root_user_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RootJournalDrawer extends StatelessWidget {
  const RootJournalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      width: (MediaQuery.of(context).size.width * 0.85).clamp(280, 400),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const RootUserHeader(),
          Expanded(
            child: BlocBuilder<RootJournalBloc, RootJournalState>(
              builder: (context, state) {
                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 16,
                      ),
                    ),
                    for (
                      var year = state.endYear;
                      year >= state.startYear;
                      year--
                    )
                      _buildYearTile(context, year, year == state.year),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        height:
                            16 +
                            MediaQuery.of(context).padding.bottom +
                            kToolbarHeight,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearTile(BuildContext context, int year, bool isCurrentYear) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onPressed: () {
          context.read<RootJournalBloc>().add(
            RootJournalYearChanged(year: year),
          );
          Scaffold.of(context).closeDrawer();
        },
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: Text(
                year.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isCurrentYear)
              Icon(
                FontAwesomeIcons.check,
                size: 16,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
