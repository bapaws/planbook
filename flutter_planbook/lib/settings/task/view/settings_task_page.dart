import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:flutter_planbook/settings/home/view/settings_section_header.dart';
import 'package:flutter_planbook/settings/task/cubit/settings_task_cubit.dart';
import 'package:flutter_planbook/settings/task/model/task_auto_note_rule.dart';
import 'package:flutter_planbook/settings/task/model/task_priority_style.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:pull_down_button/pull_down_button.dart';

@RoutePage()
class SettingsTaskPage extends StatelessWidget {
  const SettingsTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsTaskCubit(
        settingsRepository: context.read(),
      )..onRequested(),
      child: const _SettingsTaskPage(),
    );
  }
}

class _SettingsTaskPage extends StatelessWidget {
  const _SettingsTaskPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(context.l10n.task),
        leading: const NavigationBarBackButton(),
      ),
      body: ListView(
        children: [
          SettingsRow(
            onPressed: () {
              final isPlayingCompletedSound = context
                  .read<SettingsTaskCubit>()
                  .state
                  .isPlayingCompletedSound;
              context.read<SettingsTaskCubit>().onCompletedSoundChanged(
                isPlaying: !isPlayingCompletedSound,
              );
            },
            leading: const Icon(
              FontAwesomeIcons.solidBell,
              size: 20,
              color: Colors.blue,
            ),
            title: Text(context.l10n.completedSound),
            trailing: BlocSelector<SettingsTaskCubit, SettingsTaskState, bool>(
              selector: (state) => state.isPlayingCompletedSound,
              builder: (context, isPlayingCompletedSound) => CupertinoSwitch(
                value: isPlayingCompletedSound,
                onChanged: (value) {
                  context.read<SettingsTaskCubit>().onCompletedSoundChanged(
                    isPlaying: value,
                  );
                },
              ),
            ),
          ),
          PullDownButton(
            buttonAnchor: PullDownMenuAnchor.end,
            itemBuilder: (context) {
              final selectedStyle = context
                  .read<SettingsTaskCubit>()
                  .state
                  .priorityStyle;
              return [
                for (final style in TaskPriorityStyle.values)
                  PullDownMenuItem.selectable(
                    title: style.getTitle(context),
                    iconWidget: Icon(
                      style.getIcon(),
                      size: 20,
                    ),
                    selected: style == selectedStyle,
                    onTap: () {
                      if (!context.read<AppPurchasesBloc>().isPremium) {
                        context.router.push(const AppPurchasesRoute());
                        return;
                      }
                      context.read<SettingsTaskCubit>().onPriorityStyleChanged(
                        style,
                      );
                    },
                  ),
              ];
            },
            buttonBuilder: (context, showMenu) =>
                BlocSelector<
                  SettingsTaskCubit,
                  SettingsTaskState,
                  TaskPriorityStyle
                >(
                  selector: (state) => state.priorityStyle,
                  builder: (context, priorityStyle) => SettingsRow(
                    onPressed: showMenu,
                    leading: const Icon(
                      FontAwesomeIcons.solidFlag,
                      size: 20,
                      color: Colors.lime,
                    ),
                    title: Text(context.l10n.priorityHeaderStyle),
                    additionalInfo: Text(
                      priorityStyle.getTitle(context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
          ),
          SettingsSectionHeader(
            title: context.l10n.noteRules,
          ),
          for (final priority in TaskPriority.values.reversed)
            _buildPriorityItem(context, priority),
        ],
      ),
    );
  }

  Widget _buildPriorityItem(BuildContext context, TaskPriority priority) {
    final colorScheme = priority.getColorScheme(context);
    final theme = Theme.of(context);
    return BlocSelector<
      SettingsTaskCubit,
      SettingsTaskState,
      TaskAutoNoteRule?
    >(
      selector: (state) => state.taskAutoNoteRules.firstWhereOrNull(
        (rule) => rule.priority == priority,
      ),
      builder: (context, taskAutoNoteRule) {
        return PullDownButton(
          buttonAnchor: PullDownMenuAnchor.end,
          itemBuilder: (context) {
            final rules = context
                .read<SettingsTaskCubit>()
                .state
                .taskAutoNoteRules;
            return [
              PullDownMenuTitle(title: Text(context.l10n.noteRuleDescription)),
              for (final type in TaskAutoNoteType.values)
                PullDownMenuItem.selectable(
                  title: type.getTitle(context),
                  subtitle: type.getDescription(context),
                  selected: rules.any(
                    (rule) => rule.priority == priority && rule.type == type,
                  ),
                  onTap: () {
                    if (!context.read<AppPurchasesBloc>().isPremium) {
                      context.router.push(const AppPurchasesRoute());
                      return;
                    }
                    context.read<SettingsTaskCubit>().onPriorityRuleTypeChanged(
                      priority,
                      type,
                    );
                  },
                ),
            ];
          },
          buttonBuilder: (context, showMenu) => SettingsRow(
            onPressed: showMenu,
            leading: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${priority.value}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              switch (priority) {
                TaskPriority.high => context.l10n.importantUrgent,
                TaskPriority.medium => context.l10n.importantNotUrgent,
                TaskPriority.low => context.l10n.urgentUnimportant,
                TaskPriority.none => context.l10n.notUrgentUnimportant,
              },
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            additionalInfo: Text(
              taskAutoNoteRule?.type.getTitle(context) ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
