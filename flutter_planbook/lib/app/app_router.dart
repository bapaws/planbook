import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.gr.dart';

export 'package:auto_route/auto_route.dart';

export 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.cupertino();

  @override
  List<AutoRouteGuard> get guards => [];

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      initial: true,
      page: RootHomeRoute.page,
      children: [
        AutoRoute(
          page: RootTaskRoute.page,
          children: [
            AutoRoute(page: TaskInboxRoute.page),
            AutoRoute(page: TaskTodayRoute.page),
            AutoRoute(page: TaskListRoute.page),
          ],
        ),
        AutoRoute(
          page: RootNoteRoute.page,
          children: [
            AutoRoute(page: NoteTimelineRoute.page),
            AutoRoute(page: NoteGalleryRoute.page),
          ],
        ),
      ],
    ),

    // AutoRoute(page: TaskNewRoute.page),
    CustomRoute<void>(
      page: TaskNewRoute.page,
      customRouteBuilder: <T>(context, child, page) {
        return ModalBottomSheetRoute<T>(
          settings: page,
          builder: (context) => child,
          isScrollControlled: true,
          clipBehavior: Clip.hardEdge,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(),
        );
      },
    ),
    CustomRoute<void>(
      page: TaskPickerRoute.page,
      customRouteBuilder: <T>(context, child, page) {
        return ModalBottomSheetRoute<T>(
          settings: page,
          builder: (context) => child,
          isScrollControlled: true,
          clipBehavior: Clip.hardEdge,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(),
        );
      },
    ),

    AutoRoute(page: NoteNewFullscreenRoute.page),
    CustomRoute<void>(
      page: NoteNewRoute.page,
      customRouteBuilder: <T>(context, child, page) {
        return ModalBottomSheetRoute<T>(
          settings: page,
          builder: (context) => child,
          isScrollControlled: true,
          clipBehavior: Clip.hardEdge,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(),
        );
      },
    ),

    AutoRoute(page: TagListRoute.page),
    CustomRoute<void>(
      page: TagPickerRoute.page,
      customRouteBuilder: <T>(context, child, page) {
        return ModalBottomSheetRoute<T>(
          settings: page,
          builder: (context) => child,
          isScrollControlled: true,
          clipBehavior: Clip.hardEdge,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(),
        );
      },
    ),

    AutoRoute(page: SettingsHomeRoute.page),
    AutoRoute(page: FeedbackRoute.page),
    AutoRoute(page: AboutRoute.page),
    AutoRoute(page: SettingsDarkModeRoute.page),
    AutoRoute(page: SettingsSeedColorRoute.page),
    AutoRoute(page: SettingsIconRoute.page),
    CustomRoute<void>(
      page: TagNewRoute.page,
      customRouteBuilder: <T>(context, child, page) {
        return ModalBottomSheetRoute<T>(
          settings: page,
          builder: (context) => child,
          isScrollControlled: true,
          clipBehavior: Clip.hardEdge,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(),
        );
      },
    ),
  ];
}
