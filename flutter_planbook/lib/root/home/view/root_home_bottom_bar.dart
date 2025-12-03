import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const double kRootBottomBarHeight = kToolbarHeight + 8;
const double kRootBottomBarItemHeight = kToolbarHeight;
const double kRootBottomBarItemWidth = kToolbarHeight + 16;

class RootHomeBottomBar extends StatelessWidget {
  const RootHomeBottomBar({super.key});

  static const Duration animationDuration = Durations.short4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabsRouter = context.watchTabsRouter;
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () {
                      _onTabDoubleTapped(context, 0);
                    },
                    onTap: () {
                      _onTabTapped(context, 0);
                    },
                    child: SizedBox(
                      height: kRootBottomBarItemHeight,
                      width: kRootBottomBarItemWidth,
                      child: AnimatedSwitcher(
                        duration: animationDuration,
                        child: Icon(
                          FontAwesomeIcons.solidCalendarCheck,
                          key: ValueKey(tabsRouter.activeIndex),
                          size: 24,
                          color: tabsRouter.activeIndex == 0
                              ? theme.colorScheme.onSurface
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () {
                      _onTabDoubleTapped(context, 1);
                    },
                    onTap: () {
                      _onTabTapped(context, 1);
                    },
                    child: SizedBox(
                      height: kRootBottomBarItemHeight,
                      width: kRootBottomBarItemWidth,
                      child: AnimatedSwitcher(
                        duration: animationDuration,
                        child: Icon(
                          FontAwesomeIcons.book,
                          key: ValueKey(tabsRouter.activeIndex),
                          size: 24,
                          color: tabsRouter.activeIndex == 1
                              ? theme.colorScheme.onSurface
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () {
                      _onTabDoubleTapped(context, 2);
                    },
                    onTap: () {
                      _onTabTapped(context, 2);
                    },
                    child: SizedBox(
                      height: kRootBottomBarItemHeight,
                      width: kRootBottomBarItemWidth,
                      child: AnimatedSwitcher(
                        duration: animationDuration,
                        child: Icon(
                          FontAwesomeIcons.solidCompass,
                          key: ValueKey(tabsRouter.activeIndex),
                          size: 24,
                          color: tabsRouter.activeIndex == 2
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
          onDoubleTap: () {
            _onTabDoubleTapped(context, 1);
          },
          onTap: () {
            switch (tabsRouter.activeIndex) {
              case 0:
                if (kDebugMode) {
                  context.read<RootHomeBloc>().add(
                    const RootHomeDownloadJournalDayRequested(),
                  );
                  return;
                }
                context.router.push(NoteNewRoute());
              case 1:
                context.read<RootHomeBloc>().add(
                  const RootHomeDownloadJournalDayRequested(),
                );
              case 2:
                context.router.push(NoteNewRoute());
            }
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
                tabsRouter.activeIndex == 0
                    ? FontAwesomeIcons.plus
                    : FontAwesomeIcons.featherPointed,
                key: ValueKey(tabsRouter.activeIndex),
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    context.tabsRouter.setActiveIndex(index);
  }

  void _onTabDoubleTapped(BuildContext context, int index) {
    final activeIndex = context.tabsRouter.activeIndex;
    if (activeIndex != index) {
      return;
    }
  }
}
