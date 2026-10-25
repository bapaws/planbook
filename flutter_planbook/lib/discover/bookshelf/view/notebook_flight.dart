import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/bookshelf/model/notebook_kind.dart';

/// 书架推入阅读页前写入，阅读页在首帧取走。
///
/// 封面矩形和测试用阅读器不能放进路由参数，它们只在这次打开期间有效。
class NotebookLaunchRequest {
  const NotebookLaunchRequest({
    required this.sourceRect,
    required this.coverRectOf,
    this.readerBuilder,
    this.productionChrome = true,
    this.onClosed,
  });

  /// 点击时书架封面的全局矩形，飞行起点。
  final Rect sourceRect;

  /// 合书后再量一次，避免书架在阅读期间发生位移。
  final Rect? Function() coverRectOf;

  /// 测试注入阅读器；正式环境使用计划本或日记本页面。
  final Widget Function(BuildContext context, NotebookKind kind)? readerBuilder;

  /// 正式环境显示计划本标题和菜单；测试只保留关闭按钮。
  final bool productionChrome;

  /// 飞回书架、路由卸载后再通知，底部按钮这时才恢复。
  final VoidCallback? onClosed;
}

class NotebookLaunch {
  static NotebookLaunchRequest? request;

  static NotebookLaunchRequest? take() {
    final value = request;
    request = null;
    return value;
  }
}

const kNotebookFlightDuration = Duration(milliseconds: 300);

/// 与原先书架内缩放相同的缓动，遮罩和封面飞行共用。
double notebookFlightProgress(double t) => Curves.easeInOutCubic.transform(t);

/// 阅读页背后的白色毛玻璃。点在书本和工具栏以外的区域会关闭阅读页。
///
/// 模糊半径跟着飞行进度走。外层透明度压不住 [BackdropFilter]，
/// 否则背景会先糊完，封面再缩小。
///
/// 路由保持透明，书架才会留在下面被模糊。遮罩盖住的是发现页导航器，
/// 盖不住首页叠在导航器上面的底部 Tab。
Widget notebookFlightScrim({
  required double progress,
  required VoidCallback onTap,
}) {
  return _NotebookFlightScrim(progress: progress, onTap: onTap);
}

class _NotebookFlightScrim extends StatelessWidget {
  const _NotebookFlightScrim({required this.progress, required this.onTap});

  final double progress;
  final VoidCallback onTap;

  static const _sigma = 32.0;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final sigma = _sigma * t;
    final veil = ColoredBox(
      color: Color.fromRGBO(255, 255, 255, 0.4 * t),
    );
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: sigma < 0.5
            ? veil
            : ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: veil,
                ),
              ),
      ),
    );
  }
}

/// 阅读页用来在量完封面后启动飞行，不依赖路由的泛型参数。
abstract interface class NotebookFlightHost {
  void startFlight();

  /// 封面坐标量完之前，飞行还停在起点。
  bool get flightStarted;
}

/// 阅读页路由：先停在起点，等封面量完再沿路由动画飞到阅读位置。
class NotebookFlightRoute<T> extends PageRouteBuilder<T>
    implements NotebookFlightHost {
  NotebookFlightRoute({required WidgetBuilder builder, super.settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: kNotebookFlightDuration,
        reverseTransitionDuration: kNotebookFlightDuration,
        opaque: false,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      );

  var _started = false;

  @override
  bool get flightStarted => _started;

  @override
  void startFlight() {
    if (_started) return;
    _started = true;
    controller?.forward();
  }

  @override
  // 不能调用 super：它会立刻播放过渡，封面还没量到阅读位置。
  // ignore: must_call_super
  TickerFuture didPush() {
    // HeroController 会在动画值为 0 时把新路由挪到屏外量终点。
    // 这里先停在几乎为 0 的位置，避免书架整页闪一下。
    controller?.value = 0.001;
    return TickerFuture.complete()..then<void>((_) {
      if (requestFocus) {
        navigator?.focusNode.enclosingScope?.requestFocus();
      }
    });
  }

  @override
  bool get popGestureEnabled => false;
}

Route<T> notebookReaderFlightBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page,
) {
  return NotebookFlightRoute<T>(settings: page, builder: (_) => child);
}
