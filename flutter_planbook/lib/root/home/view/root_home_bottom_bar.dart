import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

const double kRootBottomBarHeight = kToolbarHeight + 8;
const double kRootBottomBarItemHeight = kToolbarHeight;
const double kRootBottomBarItemWidth = kToolbarHeight + 16;

enum RootHomeTab {
  task,
  journal,
  note;

  IconData get icon => switch (this) {
    RootHomeTab.task => FontAwesomeIcons.solidCalendarCheck,
    RootHomeTab.journal => FontAwesomeIcons.solidCompass,
    RootHomeTab.note => FontAwesomeIcons.book,
  };

  IconData get actionIcon => switch (this) {
    RootHomeTab.task => FontAwesomeIcons.plus,
    RootHomeTab.journal => FontAwesomeIcons.download,
    RootHomeTab.note => FontAwesomeIcons.featherPointed,
  };
}

class RootHomeBottomBar extends StatelessWidget {
  const RootHomeBottomBar({super.key});

  static const Duration animationDuration = Durations.short4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabsRouter = context.watchTabsRouter;
    final activeTab = RootHomeTab.values[tabsRouter.activeIndex];
    return Row(
      children: [
        Container(
          width: kRootBottomBarItemWidth * 3,
          height: kRootBottomBarItemHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.surfaceContainerHighest,
                blurRadius: 12,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: animationDuration,
                top: 2,
                left: 2 + tabsRouter.activeIndex * kRootBottomBarItemWidth,
                bottom: 2,
                child: Container(
                  width: kRootBottomBarItemWidth - 4,
                  height: kRootBottomBarItemHeight - 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final tab in RootHomeTab.values)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _onTabTapped(context, tab);
                      },
                      child: SizedBox(
                        height: kRootBottomBarItemHeight,
                        width: kRootBottomBarItemWidth,
                        child: AnimatedSwitcher(
                          duration: animationDuration,
                          child: Icon(
                            tab.icon,
                            key: ValueKey(tab),
                            size: 24,
                            color: activeTab == tab
                                ? theme.colorScheme.onSurface
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: () {},
          onTap: () {
            final activeTab = RootHomeTab.values[tabsRouter.activeIndex];
            _onActionTapped(context, activeTab);
          },
          child: Container(
            width: kRootBottomBarItemHeight,
            height: kRootBottomBarItemHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(kRootBottomBarItemHeight),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.surfaceContainerHighest,
                  blurRadius: 12,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: AnimatedSwitcher(
              duration: animationDuration,
              child: Icon(
                activeTab.actionIcon,
                key: ValueKey(activeTab),
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onTabTapped(BuildContext context, RootHomeTab tab) {
    HapticFeedback.lightImpact();
    context.tabsRouter.setActiveIndex(tab.index);
  }

  Future<void> _onActionTapped(BuildContext context, RootHomeTab tab) async {
    unawaited(HapticFeedback.lightImpact());

    switch (tab) {
      case RootHomeTab.task:
        if (await context.read<AppPurchasesBloc>().isTaskLimitReached() &&
            context.mounted) {
          await context.router.push(const AppPurchasesRoute());
          return;
        }
        final tabsRouter =
            context.tabsRouter.childControllers.firstOrNull as TabsRouter?;
        if (tabsRouter == null) return;

        final activeIndex = tabsRouter.activeIndex;
        final tab = RootTaskTab.values[activeIndex];
        final dueAt = switch (tab) {
          RootTaskTab.inbox => null,
          RootTaskTab.day => context.read<TaskTodayBloc>().state.date,
          _ => Jiffy.now().startOf(Unit.day),
        };
        await context.router.push(TaskNewRoute(dueAt: dueAt));
      case RootHomeTab.journal:
        context.read<RootHomeBloc>().add(
          const RootHomeDownloadJournalDayRequested(),
        );
      case RootHomeTab.note:
        if (await context.read<AppPurchasesBloc>().isNoteLimitReached() &&
            context.mounted) {
          await context.router.push(const AppPurchasesRoute());
          return;
        }
        await context.router.push(NoteNewRoute());
    }
  }
}
