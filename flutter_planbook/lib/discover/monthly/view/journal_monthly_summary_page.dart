import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/model/journal_date.dart';
import 'package:flutter_planbook/discover/monthly/bloc/journal_monthly_bloc.dart';
import 'package:flutter_planbook/discover/monthly/journal_monthly_bloc_manager.dart';
import 'package:flutter_planbook/discover/monthly/view/journal_monthly_calendar_view.dart';
import 'package:flutter_planbook/discover/monthly/view/journal_monthly_photo_wall.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class JournalMonthlySummaryPage extends StatelessWidget {
  const JournalMonthlySummaryPage({
    required this.date,
    required this.isLeft,
    super.key,
  });

  final JournalDate date;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    final month = date.monthStart;
    final bloc = context.read<JournalMonthlyBlocManager>().blocForMonth(
      month: month,
    );

    return BlocProvider.value(
      value: bloc,
      child: _JournalMonthlySummaryContent(
        month: month,
        isLeft: isLeft,
      ),
    );
  }
}

class _JournalMonthlySummaryContent extends StatelessWidget {
  const _JournalMonthlySummaryContent({
    required this.month,
    required this.isLeft,
  });

  final Jiffy month;
  final bool isLeft;

  void _editSummary(BuildContext context, JournalMonthlyState state) {
    context.router.push(
      NoteNewTypeRoute(
        type: NoteType.monthlySummary,
        focusAt: state.month,
        initialNote: state.summaryNote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return JournalPage(
      padding: const EdgeInsets.all(20),
      child: BlocBuilder<JournalMonthlyBloc, JournalMonthlyState>(
        builder: (context, state) {
          final l10n = context.l10n;
          if (isLeft) {
            return JournalMonthlyPhotoWall(images: state.images);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${month.month}${NoteType.monthlySummary.getTitle(l10n)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _editSummary(context, state),
                  child: JournalMonthlyCalendarView(
                    month: month,
                    footerNote: state.summaryNote,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
