import 'package:flutter/material.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';

/// 翻页条贴在首页底栏那一行，并相对屏幕居中，不挤占书本高度。
class NotebookPageNavigation extends StatelessWidget {
  const NotebookPageNavigation({required this.child, super.key});

  final Widget child;

  /// 和首页底栏同一条底边：底栏 `bottom: 22`，再让出系统导航条。
  static double bottom(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final navigationBarInset =
        Theme.of(context).platform == TargetPlatform.android
        ? (mediaQuery.viewPadding.bottom -
                  mediaQuery.systemGestureInsets.bottom)
              .clamp(0.0, double.infinity)
        : 0.0;
    return 22 + navigationBarInset;
  }

  /// 书本在这条底边之上居中，避免画进 Tab 栏。
  static double bookReserve(BuildContext context) =>
      bottom(context) + kRootBottomBarItemHeight;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom(context),
      height: kRootBottomBarItemHeight,
      child: Center(child: child),
    );
  }
}
