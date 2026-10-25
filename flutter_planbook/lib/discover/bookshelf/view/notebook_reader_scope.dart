import 'dart:async';

import 'package:flutter/material.dart';

/// 让不同翻页引擎向书架提供一致的开合操作与封面坐标。
class NotebookReaderController extends ChangeNotifier {
  final _disposed = Completer<void>();
  Object? _owner;
  Future<void> Function()? _open;
  Future<void> Function()? _close;
  Future<void> Function()? _edit;
  Rect? Function()? _coverRect;
  bool _controlsVisible = false;

  VoidCallback? onCoverClosed;

  bool get controlsVisible => _controlsVisible;
  Rect? get coverRect => _coverRect?.call();

  void attach(
    Object owner, {
    required Future<void> Function() open,
    required Future<void> Function() close,
    required Rect? Function() coverRect,
  }) {
    _owner = owner;
    _open = open;
    _close = close;
    _coverRect = coverRect;
  }

  /// 日记本把当前页的编辑交给阅读页右上角菜单。
  void bindEdit(Object owner, Future<void> Function()? edit) {
    if (!identical(owner, _owner)) return;
    _edit = edit;
  }

  Future<void> edit() async => _edit?.call();

  void detach(Object owner) {
    if (!identical(owner, _owner)) return;
    _owner = null;
    _open = null;
    _close = null;
    _edit = null;
    _coverRect = null;
  }

  Future<void> open() async => _open?.call();
  Future<void> close() async => _close?.call();

  /// 等待当前翻页落定，避免关闭操作被正在运行的引擎忽略。
  Future<void> waitForIdle(
    Listenable animation,
    bool Function() isAnimating,
  ) async {
    if (!isAnimating()) return;
    final idle = Completer<void>();
    void check() {
      if (!isAnimating() && !idle.isCompleted) idle.complete();
    }

    animation.addListener(check);
    try {
      await Future.any([idle.future, _disposed.future]);
    } finally {
      animation.removeListener(check);
    }
  }

  @override
  void dispose() {
    if (!_disposed.isCompleted) _disposed.complete();
    super.dispose();
  }

  void showControls({required bool visible}) {
    if (visible == _controlsVisible) return;
    _controlsVisible = visible;
    notifyListeners();
  }
}

class NotebookReaderScope extends InheritedWidget {
  const NotebookReaderScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final NotebookReaderController controller;

  static NotebookReaderController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NotebookReaderScope>()
      ?.controller;

  @override
  bool updateShouldNotify(NotebookReaderScope oldWidget) =>
      oldWidget.controller != controller;
}

/// 开合时只隐藏工具栏，保留占位，避免书本位置随动画跳动。
class NotebookReaderChrome extends StatelessWidget {
  const NotebookReaderChrome({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = NotebookReaderScope.maybeOf(context);
    if (controller == null) return child;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Visibility(
        visible: controller.controlsVisible,
        maintainSize: true,
        maintainState: true,
        maintainAnimation: true,
        child: child,
      ),
    );
  }
}

Rect? notebookRenderRect(BuildContext? context) {
  final box = context?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  // 必须包含缩放与透视变换，不能将局部 size 当成屏幕上的封面尺寸。
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}

Rect? notebookDescendantRect(BuildContext? root, Key key) {
  Rect? result;
  void visit(Element element) {
    if (result != null) return;
    if (element.widget.key == key) {
      result = notebookRenderRect(element);
      return;
    }
    element.visitChildren(visit);
  }

  if (root is Element) visit(root);
  return result;
}
