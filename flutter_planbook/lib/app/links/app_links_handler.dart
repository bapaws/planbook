import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

/// 统一处理应用内外的 App Links / Deep Links。
///
/// - 冷启动时通过 [AppLinks.getInitialLink] 获取 deep link
/// - App 后台运行时通过 [AppLinks.uriLinkStream] 监听 deep link
///
/// 当前支持的 URL Scheme：
/// - `planbook.bapaws://task/new?priority=high|medium|low|none&dueAt=yyyy-MM-dd`
/// - `planbook.bapaws://note/new`
class AppLinksHandler {
  AppLinksHandler({required RootStackRouter router}) : _router = router;

  final RootStackRouter _router;
  StreamSubscription<Uri>? _subscription;

  /// 初始化监听，应在应用最顶层（如 App 的 initState）调用。
  void init() {
    final appLinks = AppLinks();

    // 处理冷启动时的 deep link
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handle(uri);
        });
      }
    });

    // 处理后台运行时的 deep link
    _subscription = appLinks.uriLinkStream.listen(_handle);
  }

  /// 释放资源，应在对应 Widget 的 dispose 中调用。
  void dispose() {
    unawaited(_subscription?.cancel());
  }

  void _handle(Uri uri) {
    if (uri.scheme != kAppUrlScheme) return;

    switch (uri.host) {
      case 'task':
        _handleTask(uri);
      case 'note':
        _handleNote(uri);
    }
  }

  void _handleTask(Uri uri) {
    switch (uri.path) {
      case '/new':
        final priorityValue = uri.queryParameters['priority'];
        final dueAtStr = uri.queryParameters['dueAt'];

        final priority = switch (priorityValue) {
          'high' => TaskPriority.high,
          'medium' => TaskPriority.medium,
          'low' => TaskPriority.low,
          'none' => TaskPriority.none,
          _ => null,
        };

        final dueAt = dueAtStr != null
            ? Jiffy.parse(dueAtStr, pattern: 'yyyy-MM-dd')
            : null;

        _router.push(TaskNewRoute(dueAt: dueAt, priority: priority));
    }
  }

  void _handleNote(Uri uri) {
    switch (uri.path) {
      case '/new':
        _router.push(NoteNewRoute());
    }
  }
}
