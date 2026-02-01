import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/discover/play/cubit/discover_journal_play_cubit.dart';
import 'package:flutter_planbook/discover/play/view/discover_journal_date_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class DiscoverJournalPlayPage extends StatelessWidget {
  const DiscoverJournalPlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DiscoverJournalPlayCubit(),
      child: const _DiscoverJournalPlayPage(),
    );
  }
}

class _DiscoverJournalPlayPage extends StatelessWidget {
  const _DiscoverJournalPlayPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppBar(
              leading: const NavigationBarCloseButton(),
              title: Text(context.l10n.autoPlay),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 16),
                for (final unit in [Unit.week, Unit.month, Unit.year]) ...[
                  CupertinoButton.tinted(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    child: Text(
                      switch (unit) {
                        Unit.week => context.l10n.thisWeek,
                        Unit.month => context.l10n.thisMonth,
                        Unit.year => context.l10n.thisYear,
                        _ => throw UnimplementedError(),
                      },
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    onPressed: () {
                      final now = Jiffy.now();
                      final from = now.startOf(unit);
                      context.read<DiscoverJournalPlayCubit>().onFromChanged(
                        from,
                      );
                      final to = now.endOf(unit);
                      context.read<DiscoverJournalPlayCubit>().onToChanged(to);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            BlocSelector<
              DiscoverJournalPlayCubit,
              DiscoverJournalPlayState,
              Jiffy
            >(
              selector: (state) => state.from,
              builder: (context, from) => Row(
                children: [
                  const SizedBox(width: 16),
                  Text(context.l10n.startDate),
                  const Spacer(),
                  DiscoverJournalDateView(
                    date: from,
                    onDateChanged: (date) {
                      context.read<DiscoverJournalPlayCubit>().onFromChanged(
                        date,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BlocSelector<
              DiscoverJournalPlayCubit,
              DiscoverJournalPlayState,
              Jiffy
            >(
              selector: (state) => state.to,
              builder: (context, to) => Row(
                children: [
                  const SizedBox(width: 16),
                  Text(context.l10n.endDate),
                  const Spacer(),
                  DiscoverJournalDateView(
                    date: to,
                    onDateChanged: (date) {
                      context.read<DiscoverJournalPlayCubit>().onToChanged(
                        date,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(kMinInteractiveDimension),
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(kToolbarHeight),
                child: SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      context.l10n.startPlaying,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                onPressed: () {
                  final state = context.read<DiscoverJournalPlayCubit>().state;
                  context.router.pop({
                    'from': state.from,
                    'to': state.to,
                  });
                },
              ),
            ),
            SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
