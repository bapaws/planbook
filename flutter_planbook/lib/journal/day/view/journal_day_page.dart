import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/journal/day/bloc/journal_day_bloc.dart';
import 'package:flutter_planbook/journal/day/view/journal_day_date_view.dart';
import 'package:flutter_planbook/journal/day/view/journal_day_focus_view.dart';
import 'package:flutter_planbook/journal/day/view/journal_day_stat_card.dart';
import 'package:flutter_planbook/journal/note/bloc/journal_note_bloc.dart';
import 'package:flutter_planbook/journal/note/view/journal_note_cover_view.dart';
import 'package:flutter_planbook/journal/note/view/journal_note_page.dart';
import 'package:flutter_planbook/journal/priority/bloc/journal_priority_bloc.dart';
import 'package:flutter_planbook/journal/timeline/bloc/journal_timeline_bloc.dart';
import 'package:flutter_planbook/journal/timeline/view/journal_timeline_page.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:screenshot/screenshot.dart';

const double kJournalPageWidth = 296 * 2.5;
const double kJournalPageHeight = 210 * 2.5;

@RoutePage()
class JournalDayPage extends StatelessWidget {
  const JournalDayPage({required this.date, super.key});

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => JournalDayBloc(
            date: date,
            tasksRepository: context.read(),
            notesRepository: context.read(),
          )..add(JournalDayRequested(date: date)),
        ),
        BlocProvider(
          create: (context) {
            final bloc = JournalPriorityBloc(
              tasksRepository: context.read(),
            );
            for (final priority in TaskPriority.values) {
              bloc.add(
                JournalPriorityRequested(date: date, priority: priority),
              );
            }
            return bloc;
          },
        ),
        BlocProvider(
          create: (context) =>
              JournalTimelineBloc(
                  tasksRepository: context.read(),
                )
                ..add(JournalTimelineRequested(date: date))
                ..add(JournalTimelineTaskCountRequested(date: date)),
        ),
        BlocProvider(
          create: (context) => JournalNoteBloc(
            notesRepository: context.read(),
          )..add(JournalNoteRequested(date: date)),
        ),
      ],
      child: _JournalDayPage(date: date),
    );
  }
}

class _JournalDayPage extends StatefulWidget {
  const _JournalDayPage({
    required this.date,
  });

  final Jiffy date;

  @override
  State<_JournalDayPage> createState() => _JournalDayPageState();
}

class _JournalDayPageState extends State<_JournalDayPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const spacing = 16.0;
    final width = ((kJournalPageWidth - 20 - spacing * 2) / 3).floorToDouble();
    return Container(
      width: kJournalPageWidth,
      height: kJournalPageHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          // strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Row(
        spacing: spacing,
        children: [
          SizedBox(
            width: width,
            height: kJournalPageHeight - 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JournalDayDateView(date: widget.date),
                BlocBuilder<JournalTimelineBloc, JournalTimelineState>(
                  builder: (context, state) {
                    final totalTasks = state.taskCount;
                    final completedTasks = state.completedTaskCount;
                    final completionRate = totalTasks > 0
                        ? (completedTasks / totalTasks * 100).toStringAsFixed(
                            0,
                          )
                        : '0';
                    return JournalDayStatCard(
                      icon: '📋',
                      title: context.l10n.task,
                      children: [
                        JournalDayStatItem(
                          label: context.l10n.total,
                          value: totalTasks.toString(),
                        ),
                        JournalDayStatItem(
                          label: context.l10n.completed,
                          value: completedTasks.toString(),
                        ),
                        JournalDayStatItem(
                          label: context.l10n.completionRate,
                          value: '$completionRate%',
                        ),
                      ],
                    );
                  },
                ),
                BlocBuilder<JournalNoteBloc, JournalNoteState>(
                  builder: (context, state) {
                    return JournalDayStatCard(
                      icon: '📝',
                      title: context.l10n.note,
                      children: [
                        JournalDayStatItem(
                          label: context.l10n.total,
                          value: state.noteCount.toString(),
                        ),
                        JournalDayStatItem(
                          label: context.l10n.words,
                          value: state.wordCount.toString(),
                        ),
                      ],
                    );
                  },
                ),
                // SizedBox(
                //   width: width,
                //   height: kJournalPageHeight / 2,
                //   child: const JournalPriorityPage(),
                // ),
                BlocSelector<JournalNoteBloc, JournalNoteState, String?>(
                  selector: (state) => state.coverImage,
                  builder: (context, coverImage) => coverImage != null
                      ? JournalNoteCoverView(
                          coverImage: coverImage,
                          width: width - 48,
                          height: width - 48,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          SizedBox(
            width: width,
            height: kJournalPageHeight - 12,
            child: const JournalTimelinePage(),
          ),
          SizedBox(
            width: width,
            height: kJournalPageHeight - 12,
            child: JournalNotePage(date: widget.date),
          ),
        ],
      ),
    );
  }

  Future<void> _capture() async {
    final imageBytes = await _screenshotController.capture();
    if (imageBytes == null) return;
    try {
      await EasyLoading.show(status: '保存中...');
      final dateStr =
          '${widget.date.year}-'
          '${widget.date.month.toString().padLeft(2, '0')}-'
          '${widget.date.date.toString().padLeft(2, '0')}';
      final result = await AppImageSaver.saveImage(
        imageBytes,
        fileName: 'Journal_$dateStr',
      );
      await EasyLoading.dismiss();
      if (result.isSuccess) {
        await EasyLoading.showSuccess('已保存到相册');
      } else {
        await EasyLoading.showError('保存失败');
      }
    } on Exception catch (_) {
      await EasyLoading.dismiss();
      await EasyLoading.showError('保存失败');
    }
  }
}
