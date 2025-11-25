import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const double kRootBottomBarHeight = kToolbarHeight + 8;
const double kRootBottomBarItemHeight = kToolbarHeight;
const double kRootBottomBarItemWidth = kToolbarHeight + 16;

class RootHomeBottomBar extends StatelessWidget {
  const RootHomeBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabsRouter = context.watchTabsRouter;
    return Row(
      children: [
        Container(
          width: kRootBottomBarItemWidth * 2,
          height: kRootBottomBarItemHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          clipBehavior: Clip.hardEdge,

          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
              child: Row(
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
                      child: Icon(
                        FontAwesomeIcons.listCheck,
                        size: 24,
                        color: tabsRouter.activeIndex == 0
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
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
                      child: Icon(
                        FontAwesomeIcons.box,
                        size: 24,
                        color: tabsRouter.activeIndex == 1
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: () {
            _onTabDoubleTapped(context, 1);
          },
          onTap: () {
            if (tabsRouter.activeIndex == 0) {
              context.router.push(TaskNewRoute());
            } else {
              context.router.push(NoteNewRoute());
            }
          },
          child: Container(
            width: kRootBottomBarItemHeight,
            height: kRootBottomBarItemHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHighest,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    tabsRouter.activeIndex == 0
                        ? FontAwesomeIcons.plus
                        : FontAwesomeIcons.featherPointed,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
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
