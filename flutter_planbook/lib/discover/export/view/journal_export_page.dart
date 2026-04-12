import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/view/app_date_picker.dart';
import 'package:flutter_planbook/core/view/app_pro_view.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/discover/daily/journal_daily_bloc_manager.dart';
import 'package:flutter_planbook/discover/export/bloc/journal_export_bloc.dart';
import 'package:flutter_planbook/discover/export/view/discover_journal_horizontal_view.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:share_plus/share_plus.dart';

/// 结束日期晚于开始日期（跨日历日）时，批量导出图片为会员能力。
bool _journalExportRangeIsMultiDay(JournalExportReady e) {
  return !e.startDate.isSame(e.endDate, unit: Unit.day);
}

@RoutePage()
class JournalExportPage extends StatelessWidget {
  const JournalExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JournalExportBloc(),
      child: const _JournalExportNestedProviders(),
    );
  }
}

class _JournalExportNestedProviders extends StatelessWidget {
  const _JournalExportNestedProviders();

  @override
  Widget build(BuildContext context) {
    final start =
        (context.read<JournalExportBloc>().state as JournalExportReady)
            .startDate;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DiscoverJournalBloc(now: start),
        ),
        RepositoryProvider(
          create: (context) => JournalDailyBlocManager(
            notesRepository: context.read(),
            tasksRepository: context.read(),
          ),
          dispose: (manager) => manager.dispose(),
        ),
      ],
      child: const _JournalExportControllerScope(),
    );
  }
}

/// 持有导出控制器，并在首帧预取日记 Bloc。
class _JournalExportControllerScope extends StatefulWidget {
  const _JournalExportControllerScope();

  @override
  State<_JournalExportControllerScope> createState() =>
      _JournalExportControllerScopeState();
}

class _JournalExportControllerScopeState
    extends State<_JournalExportControllerScope> {
  late final DiscoverJournalHorizontalExportController _exportController;

  @override
  void initState() {
    super.initState();
    _exportController = DiscoverJournalHorizontalExportController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final export =
          context.read<JournalExportBloc>().state as JournalExportReady;
      _prefetchRange(context, export);
    });
  }

  void _prefetchRange(BuildContext context, JournalExportReady s) {
    final manager = context.read<JournalDailyBlocManager>();
    final span = s.endDate.diff(s.startDate, unit: Unit.day).toInt();
    final center = s.startDate.add(days: span ~/ 2);
    final startOfYear = center.startOf(Unit.year);
    final dayCount = startOfYear
        .add(years: 1)
        .diff(startOfYear, unit: Unit.day)
        .toInt();
    final radius = (span ~/ 2 + 2).clamp(0, 14);
    manager.prefetchDaysAround(
      centerDate: center,
      dayCount: dayCount,
      radius: radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalExportBloc, JournalExportState>(
      listenWhen: (previous, current) {
        if (previous is! JournalExportReady || current is! JournalExportReady) {
          return false;
        }
        return previous.startDate != current.startDate ||
            previous.endDate != current.endDate;
      },
      listener: (context, state) {
        final s = state as JournalExportReady;
        context.read<DiscoverJournalBloc>().add(
          DiscoverJournalDateChanged(date: s.startDate),
        );
        _prefetchRange(context, s);
      },
      child: _JournalExportScaffold(
        exportController: _exportController,
      ),
    );
  }
}

class _JournalExportScaffold extends StatelessWidget {
  const _JournalExportScaffold({
    required this.exportController,
  });

  final DiscoverJournalHorizontalExportController exportController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final export =
        context.watch<JournalExportBloc>().state as JournalExportReady;
    final isPremium = context.select<AppPurchasesBloc, bool>(
      (b) => b.state.isPremium,
    );
    final isMultiDay = _journalExportRangeIsMultiDay(export);
    final theme = Theme.of(context);
    final bloc = context.read<JournalExportBloc>();

    Future<void> onExportPdf() async {
      final messenger = ScaffoldMessenger.of(context);
      final range =
          context.read<JournalExportBloc>().state as JournalExportReady;
      await EasyLoading.show(status: l10n.journalExportExporting);
      if (!context.mounted) return;
      try {
        final file = await exportController.exportJournalPdf(
          context: context,
          start: range.startDate,
          end: range.endDate,
        );
        await EasyLoading.dismiss();
        if (!context.mounted) return;
        if (file == null) {
          await EasyLoading.showError(l10n.journalExportFailed);
          return;
        }
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: l10n.journalExportTitle,
          ),
        );
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.journalExportSuccess)),
        );
      } on Object catch (_) {
        await EasyLoading.dismiss();
        if (context.mounted) {
          await EasyLoading.showError(l10n.journalExportFailed);
        }
      }
    }

    Future<void> onExportImagesBatch() async {
      final messenger = ScaffoldMessenger.of(context);
      final range =
          context.read<JournalExportBloc>().state as JournalExportReady;
      final days =
          range.endDate.diff(range.startDate, unit: Unit.day).toInt() + 1;
      final total = days * 2;

      await EasyLoading.show(
        status: l10n.journalExportSavingImages(0, total),
      );
      if (!context.mounted) return;
      try {
        final saved = await exportController.exportJournalImagesBatch(
          context: context,
          start: range.startDate,
          end: range.endDate,
          onProgress: (current, tot) {
            EasyLoading.show(
              status: l10n.journalExportSavingImages(current, tot),
            );
          },
        );
        await EasyLoading.dismiss();
        if (!context.mounted) return;
        if (saved <= 0) {
          await EasyLoading.showError(l10n.saveFailed);
          return;
        }
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.journalExportImagesSaved(saved))),
        );
      } on Object catch (_) {
        await EasyLoading.dismiss();
        if (context.mounted) {
          await EasyLoading.showError(l10n.saveFailed);
        }
      }
    }

    Future<void> onSaveCurrentPageOnly() async {
      await EasyLoading.show();
      if (!context.mounted) return;
      try {
        final ok = await exportController.exportCurrentPageImage(
          context: context,
        );
        await EasyLoading.dismiss();
        if (!context.mounted) return;
        if (ok) {
          await EasyLoading.showSuccess(l10n.saveSuccess);
        } else {
          await EasyLoading.showError(l10n.saveFailed);
        }
      } on Object catch (_) {
        await EasyLoading.dismiss();
        if (context.mounted) {
          await EasyLoading.showError(l10n.saveFailed);
        }
      }
    }

    Future<void> onExportImagesPressed() async {
      if (!isPremium && isMultiDay) {
        await context.router.push(const AppPurchasesRoute());
        return;
      }
      if (!isPremium && !isMultiDay) {
        await onSaveCurrentPageOnly();
        return;
      }
      await onExportImagesBatch();
    }

    Future<void> onExportPdfPressed() async {
      if (!isPremium) {
        await context.router.push(const AppPurchasesRoute());
        return;
      }
      await onExportPdf();
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.journalExportTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      context.l10n.journalExportStartDate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    AppDatePicker(
                      maximumDateTime: export.endDate,
                      mode: AppDatePickerMode.date,
                      date: export.startDate,
                      onDateChanged: (date) {
                        bloc.add(JournalExportStartDateChanged(date));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      context.l10n.journalExportEndDate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    AppDatePicker(
                      minimumDateTime: export.startDate,
                      mode: AppDatePickerMode.date,
                      date: export.endDate,
                      onDateChanged: (date) {
                        bloc.add(JournalExportEndDateChanged(date));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    CupertinoButton.tinted(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      onPressed: () => bloc.add(
                        const JournalExportPresetSelected(
                          JournalExportPreset.today,
                        ),
                      ),
                      child: Text(
                        l10n.today,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    CupertinoButton.tinted(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      onPressed: () => bloc.add(
                        const JournalExportPresetSelected(
                          JournalExportPreset.thisWeek,
                        ),
                      ),
                      child: Text(
                        l10n.thisWeek,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    CupertinoButton.tinted(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      onPressed: () => bloc.add(
                        const JournalExportPresetSelected(
                          JournalExportPreset.thisMonth,
                        ),
                      ),
                      child: Text(
                        l10n.thisMonth,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    CupertinoButton.tinted(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      onPressed: () => bloc.add(
                        const JournalExportPresetSelected(
                          JournalExportPreset.thisYear,
                        ),
                      ),
                      child: Text(
                        l10n.thisYear,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DiscoverJournalHorizontalView(
              listenToRootBlocs: false,
              bottomOverlayReserve: 0,
              exportController: exportController,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.fromHeight(kToolbarHeight),
                    color: theme.colorScheme.secondaryContainer,
                    onPressed: onExportPdfPressed,
                    child: _JournalExportBottomButtonLabel(
                      title: l10n.journalExportExportPdf,
                      showVipBadge: true,
                      theme: theme,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.fromHeight(kToolbarHeight),
                    color: theme.colorScheme.primaryContainer,
                    onPressed: onExportImagesPressed,
                    child: _JournalExportBottomButtonLabel(
                      title: l10n.journalExportExportImages,
                      showVipBadge: isMultiDay,
                      theme: theme,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

/// 按钮文案 + 与全站一致的 PRO（VIP）角标。
class _JournalExportBottomButtonLabel extends StatelessWidget {
  const _JournalExportBottomButtonLabel({
    required this.title,
    required this.showVipBadge,
    required this.theme,
  });

  final String title;
  final bool showVipBadge;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final proStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 12,
    );
    return Row(
      // fit: StackFit.expand,
      // alignment: Alignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (showVipBadge) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: AppProView(style: proStyle),
          ),
        ],
      ],
    );
  }
}
