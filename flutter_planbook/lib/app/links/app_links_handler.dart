import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/links/widget_deep_link.dart';
import 'package:flutter_planbook/task/week/model/task_week_view_mode.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

/// 统一处理应用内外的 App Links / Deep Links。
///
/// - 冷启动时通过 [AppLinks.getInitialLink] 获取 deep link
/// - App 后台运行时通过 [AppLinks.uriLinkStream] 监听 deep link
///
/// 当前支持的 URL Scheme：
/// - `planbook.bapaws://task/new?priority=high|medium|low|none&dueAt=yyyy-MM-dd|today`
/// - `planbook.bapaws://task/today?view=timeBlock&date=yyyy-MM-dd`
/// - `planbook.bapaws://task/week?view=grid|list&date=yyyy-MM-dd`
/// - `planbook.bapaws://task/detail?taskId=...&occurrenceAt=...`
/// - `planbook.bapaws://note/new`
/// - `planbook.bapaws://purchases`
class AppLinksHandler {
  AppLinksHandler({required this.router});

  final RootStackRouter router;
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
      case 'purchases':
        router.push(const AppPurchasesRoute());
    }
  }

  void _handleTask(Uri uri) {
    switch (uri.path) {
      case '/new':
        if (router.stackData.any((route) => route.name == TaskNewRoute.name)) {
          return;
        }

        final priorityValue = uri.queryParameters['priority'];
        final dueAtStr = uri.queryParameters['dueAt'];

        final priority = switch (priorityValue) {
          'high' => TaskPriority.high,
          'medium' => TaskPriority.medium,
          'low' => TaskPriority.low,
          'none' => TaskPriority.none,
          _ => null,
        };

        Jiffy? dueAt;
        if (dueAtStr == 'today') {
          dueAt = Jiffy.now().startOf(Unit.day);
        } else if (dueAtStr != null) {
          try {
            dueAt = Jiffy.parse(dueAtStr, pattern: 'yyyy-MM-dd');
          } on Object {
            dueAt = null;
          }
        }

        WidgetDeepLink.openCreateTask(dueAt: dueAt, priority: priority);
      case '/today':
        _openToday(
          view: uri.queryParameters['view'],
          date: _parseDate(uri.queryParameters['date']),
        );
      case '/week':
        _openWeek(
          view: uri.queryParameters['view'],
          date: _parseDate(uri.queryParameters['date']),
        );
      case '/detail':
        final taskId = uri.queryParameters['taskId'];
        if (taskId == null || taskId.isEmpty) return;

        final occurrenceAtRaw = uri.queryParameters['occurrenceAt'];
        Jiffy? occurrenceAt;
        if (occurrenceAtRaw != null && occurrenceAtRaw.isNotEmpty) {
          try {
            occurrenceAt = Jiffy.parse(occurrenceAtRaw);
          } on Object {
            occurrenceAt = null;
          }
        }
        router.push(
          TaskDetailRoute(taskId: taskId, occurrenceAt: occurrenceAt),
        );
    }
  }

  Jiffy? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return Jiffy.parse(raw, pattern: 'yyyy-MM-dd');
    } on Object {
      return null;
    }
  }

  void _openToday({String? view, Jiffy? date}) {
    unawaited(
      router.navigate(
        const RootHomeRoute(
          children: [
            RootTaskRoute(
              children: [TaskTodayRoute()],
            ),
          ],
        ),
      ),
    );
    if (date != null) {
      WidgetDeepLink.openDay(date);
    }
    if (view == 'timeBlock') {
      WidgetDeepLink.openTodayTimeBlock();
    }
  }

  void _openWeek({String? view, Jiffy? date}) {
    unawaited(
      router.navigate(
        const RootHomeRoute(
          children: [
            RootTaskRoute(
              children: [TaskWeekRoute()],
            ),
          ],
        ),
      ),
    );
    final weekViewMode = switch (view) {
      'grid' => TaskWeekViewMode.grid,
      'list' => TaskWeekViewMode.list,
      _ => null,
    };
    WidgetDeepLink.openWeek(date: date, weekViewMode: weekViewMode);
  }

  void _handleNote(Uri uri) {
    switch (uri.path) {
      case '/new':
        router.push(NoteNewRoute());
    }
  }
}
