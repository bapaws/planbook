import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/view/app_date_picker.dart';
import 'package:flutter_planbook/core/view/app_pro_view.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_view.dart';
import 'package:flutter_planbook/task/source/model/task_source_panel_type.dart';
import 'package:flutter_planbook/task/source/picker/model/task_source_panel_picker_result.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/tag_entity.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:pull_down_button/pull_down_button.dart';

/// 右侧任务来源选择器，以 bottom sheet 形式展示
///
/// 支持在「收集箱 / 标签 / 日期 / 隐藏」之间切换，并选择具体的标签或日期。
@RoutePage()
class TaskSourcePanelPickerPage extends StatelessWidget {
  const TaskSourcePanelPickerPage({
    required this.initialSourceType,
    required this.tags,
    super.key,
  });

  final TaskSourcePanelType initialSourceType;
  final List<TagEntity> tags;

  @override
  Widget build(BuildContext context) {
    final initialTags = switch (initialSourceType) {
      TaskSourcePanelTag(tags: final selected) => selected,
      _ => const <TagEntity>[],
    };

    return BlocProvider(
      create: (context) =>
          TagListBloc(
              tagsRepository: context.read(),
              mode: TagListMode.singleSelect,
            )
            ..add(const TagListRequested())
            ..add(TagListMultiSelected(tags: initialTags)),
      child: AppPageScaffold(
        borderRadius: BorderRadius.circular(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        clipBehavior: Clip.hardEdge,
        child: _TaskSourcePanelPicker(
          initialSourceType: initialSourceType,
        ),
      ),
    );
  }
}

class _TaskSourcePanelPicker extends StatefulWidget {
  const _TaskSourcePanelPicker({
    required this.initialSourceType,
  });

  final TaskSourcePanelType initialSourceType;

  @override
  State<_TaskSourcePanelPicker> createState() => _TaskSourcePanelPickerState();
}

class _TaskSourcePanelPickerState extends State<_TaskSourcePanelPicker> {
  late TaskSourcePanelTab _tab;
  late Jiffy _selectedDate;
  late TaskSourcePanelDateFilter _dateFilter;
  final GlobalKey _dateTileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedDate = Jiffy.now();
    _dateFilter = TaskSourcePanelDateFilter.all;
    switch (widget.initialSourceType) {
      case TaskSourcePanelInbox():
        _tab = TaskSourcePanelTab.inbox;
      case TaskSourcePanelTag():
        _tab = TaskSourcePanelTab.tag;
      case TaskSourcePanelDate(date: final date, filter: final filter):
        _tab = TaskSourcePanelTab.date;
        _selectedDate = date;
        _dateFilter = filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          // title: Text(context.l10n.selectSource),
          leading: const NavigationBarCloseButton(),
        ),
        _buildSourceTypeTile(context),
        AnimatedSwitcher(
          duration: Durations.medium1,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _buildOptionsView(context),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _confirm,
              borderRadius: BorderRadius.circular(24),
              child: Text(context.l10n.confirm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceTypeTile(BuildContext context) {
    final isPremium = context.select<AppPurchasesBloc, bool>(
      (bloc) => bloc.state.isPremium,
    );
    final theme = Theme.of(context);

    Widget segmentLabel(String text, {bool showPro = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showPro) ...[
              const SizedBox(width: 2),
              AppProView(
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<TaskSourcePanelTab>(
          groupValue: _tab,
          children: {
            TaskSourcePanelTab.inbox: segmentLabel(context.l10n.inbox),
            TaskSourcePanelTab.tag: segmentLabel(
              context.l10n.tag,
              showPro: !isPremium,
            ),
            TaskSourcePanelTab.date: segmentLabel(
              context.l10n.date,
              showPro: !isPremium,
            ),
            TaskSourcePanelTab.hide: segmentLabel(context.l10n.hide),
          },
          onValueChanged: (value) {
            if (value == null) return;
            // 标签 / 日期为 PRO 功能，非会员直接进入付费页
            if (!isPremium &&
                (value == TaskSourcePanelTab.tag ||
                    value == TaskSourcePanelTab.date)) {
              context.router.push(const AppPurchasesRoute());
              return;
            }
            setState(() {
              _tab = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildOptionsView(BuildContext context) {
    return switch (_tab) {
      TaskSourcePanelTab.inbox ||
      TaskSourcePanelTab.hide => const SizedBox.shrink(
        key: ValueKey('empty-option'),
      ),
      TaskSourcePanelTab.tag => ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 320,
          minHeight: 120,
        ),
        child: const TagListView(
          key: ValueKey('tag-option'),
          showAddButton: true,
        ),
      ),
      TaskSourcePanelTab.date => _buildDateOption(context),
    };
  }

  Widget _buildDateOption(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('date-option'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        SettingsRow(
          key: _dateTileKey,
          onPressed: _selectDate,
          leading: Icon(
            CupertinoIcons.calendar,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(context.l10n.date),
          additionalInfo: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _selectedDate.toLocal().yMMMd,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        PullDownButton(
          buttonAnchor: PullDownMenuAnchor.end,
          itemBuilder: (context) => [
            for (final filter in TaskSourcePanelDateFilter.values)
              PullDownMenuItem.selectable(
                title: filter.title(context),
                icon: filter.icon,
                selected: filter == _dateFilter,
                onTap: () => setState(() {
                  _dateFilter = filter;
                }),
              ),
          ],
          buttonBuilder: (context, showMenu) => SettingsRow(
            onPressed: showMenu,
            leading: Icon(
              _dateFilter.icon,
              size: 18,
              color: colorScheme.secondary,
            ),
            title: Text(context.l10n.dateFilter),
            additionalInfo: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _dateFilter.title(context),
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.tertiary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _selectDate() {
    final tileContext = _dateTileKey.currentContext;
    if (tileContext == null) return;
    showAppDatePicker(
      tileContext,
      initialDate: _selectedDate,
      onDateChanged: (date) {
        setState(() {
          _selectedDate = date;
        });
      },
    );
  }

  void _closePanel() {
    context.router.maybePop(
      const TaskSourcePanelPickerResult(closePanel: true),
    );
  }

  List<TagEntity> _selectedTags() {
    final bloc = context.read<TagListBloc>();
    final tags = bloc.state.tags;
    final selectedTagIds = bloc.state.selectedTagIds;
    return [
      for (final tagId in selectedTagIds)
        tags.firstWhere((tag) => tag.id == tagId),
    ];
  }

  void _confirm() {
    if (_tab == TaskSourcePanelTab.hide) {
      _closePanel();
      return;
    }

    final TaskSourcePanelType result;
    switch (_tab) {
      case TaskSourcePanelTab.inbox:
        result = const TaskSourcePanelInbox();
      case TaskSourcePanelTab.tag:
        final selected = _selectedTags();
        result = selected.isNotEmpty
            ? TaskSourcePanelTag(selected)
            : const TaskSourcePanelInbox();
      case TaskSourcePanelTab.date:
        result = TaskSourcePanelDate(
          _selectedDate,
          filter: _dateFilter,
        );
      case TaskSourcePanelTab.hide:
        result = const TaskSourcePanelInbox();
    }

    context.router.maybePop(
      TaskSourcePanelPickerResult(sourceType: result),
    );
  }
}

extension on TaskSourcePanelDateFilter {
  String title(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      TaskSourcePanelDateFilter.all => l10n.all,
      TaskSourcePanelDateFilter.allDay => l10n.allDay,
      TaskSourcePanelDateFilter.notAllDay => l10n.notAllDay,
    };
  }

  IconData get icon => switch (this) {
    TaskSourcePanelDateFilter.all => CupertinoIcons.calendar,
    TaskSourcePanelDateFilter.allDay => CupertinoIcons.sun_max,
    TaskSourcePanelDateFilter.notAllDay => CupertinoIcons.clock,
  };
}
