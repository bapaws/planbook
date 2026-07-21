import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_focus_view.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/model/journal_date.dart';
import 'package:flutter_planbook/discover/monthly/bloc/journal_monthly_bloc.dart';
import 'package:flutter_planbook/discover/monthly/journal_monthly_bloc_manager.dart';
import 'package:flutter_planbook/discover/monthly/view/journal_monthly_calendar_view.dart';
import 'package:flutter_planbook/discover/monthly/view/journal_monthly_week_column.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class JournalMonthlyHighlightPage extends StatelessWidget {
  const JournalMonthlyHighlightPage({
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
      child: _JournalMonthlyHighlightContent(
        month: month,
        isLeft: isLeft,
      ),
    );
  }
}

class _JournalMonthlyHighlightContent extends StatelessWidget {
  const _JournalMonthlyHighlightContent({
    required this.month,
    required this.isLeft,
  });

  final Jiffy month;
  final bool isLeft;

  void _editFocus(BuildContext context, JournalMonthlyState state) {
    context.router.push(
      NoteNewTypeRoute(
        type: NoteType.monthlyFocus,
        focusAt: state.month,
        initialNote: state.focusNote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthColorScheme = context.colorSchemeForMonth(month.month);

    return JournalPage(
      padding: EdgeInsets.fromLTRB(
        isLeft ? 0 : 0,
        kJournalPageSpacing,
        isLeft ? 0 : kJournalPageSpacing,
        kJournalPageSpacing,
      ),
      child: BlocBuilder<JournalMonthlyBloc, JournalMonthlyState>(
        builder: (context, state) {
          if (isLeft) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      // 月度开篇：以完整月名作主视觉，避免数字被误读为日期
                      const SizedBox(height: 56),
                      Text(
                        month.format(pattern: 'y'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: monthColorScheme.outline,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: double.infinity, height: 12),
                      Container(
                        width: 72,
                        height: 4,
                        decoration: BoxDecoration(
                          color: monthColorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        month.MMMM,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: 1.5,
                          color: monthColorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _editFocus(context, state),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                          constraints: const BoxConstraints(minHeight: 240),
                          alignment: Alignment.topLeft,
                          child: JournalDailyFocusView(
                            note: state.focusNote,
                            noteType: NoteType.monthlyFocus,
                            colorScheme: monthColorScheme,
                            maxLines: 20,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: monthColorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // const Spacer(),
                Expanded(
                  flex: 2,
                  child: JournalMonthlyWeekColumn(
                    month: month,
                    weeklyFocusNotes: state.weeklyFocusNotes,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: JournalMonthlyCalendarView(
                    month: month,
                    dailyFocusNotes: state.dailyFocusNotes,
                    endWeekdayColumn: 0,
                    fillHeight: true,
                  ),
                ),
              ],
            );
          }

          return JournalMonthlyCalendarView(
            month: month,
            dailyFocusNotes: state.dailyFocusNotes,
            startWeekdayColumn: 1,
            fillHeight: true,
          );
        },
      ),
    );
  }
}
