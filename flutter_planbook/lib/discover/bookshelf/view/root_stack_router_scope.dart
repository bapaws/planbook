import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

/// 把子树的 `context.router` 指回根路由。
///
/// 阅读页和书架都挂在发现页的嵌套栈上，否则计划本里的跳转会找不到根路由。
class RootStackRouterScope extends StatefulWidget {
  const RootStackRouterScope({required this.child, super.key});

  final Widget child;

  @override
  State<RootStackRouterScope> createState() => _RootStackRouterScopeState();
}

class _RootStackRouterScopeState extends State<RootStackRouterScope> {
  StackRouter? _root;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = StackRouterScope.of(context)?.controller.root;
    if (identical(next, _root)) return;
    _root?.removeListener(_rebuild);
    _root = next;
    _root?.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _root?.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final root = _root;
    if (root == null) return widget.child;
    return StackRouterScope(
      controller: root,
      stateHash: root.stateHash,
      child: widget.child,
    );
  }
}
