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

  AutoRoute _buildModalBottomSheetRoute(
    PageInfo page,
  ) {
    return CustomRoute<void>(
      page: page,
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
    );
  }

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
          ],
        ),
        AutoRoute(page: RootJournalRoute.page),
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
    _buildModalBottomSheetRoute(TaskNewRoute.page),
    _buildModalBottomSheetRoute(TaskNewRecurrenceEndAtRoute.page),

    _buildModalBottomSheetRoute(TaskPickerRoute.page),
    _buildModalBottomSheetRoute(TaskPriorityPickerRoute.page),
    _buildModalBottomSheetRoute(TaskDatePickerRoute.page),
    _buildModalBottomSheetRoute(TaskDurationRoute.page),
    _buildModalBottomSheetRoute(TaskRecurrenceRoute.page),

    AutoRoute(page: TaskDetailRoute.page),

    AutoRoute(page: NoteNewFullscreenRoute.page),
    _buildModalBottomSheetRoute(NoteNewRoute.page),

    AutoRoute(page: TagListRoute.page),
    _buildModalBottomSheetRoute(TagPickerRoute.page),
    _buildModalBottomSheetRoute(TagNewRoute.page),

    AutoRoute(page: SettingsHomeRoute.page),
    AutoRoute(page: FeedbackRoute.page),
    AutoRoute(page: AboutRoute.page),
    AutoRoute(page: SettingsDarkModeRoute.page),
    AutoRoute(page: SettingsSeedColorRoute.page),
    AutoRoute(page: SettingsIconRoute.page),

    AutoRoute(page: AppPurchasesRoute.page),

    AutoRoute(page: SignHomeRoute.page),

    AutoRoute(page: MinePasswordRoute.page),
    AutoRoute(page: MinePhoneRoute.page),
    AutoRoute(page: MineEmailRoute.page),
    AutoRoute(page: MineProfileRoute.page),
    AutoRoute(page: MineDeleteRoute.page),
  ];
}
