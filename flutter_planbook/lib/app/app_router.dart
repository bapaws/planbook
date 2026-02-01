import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.gr.dart';
import 'package:planbook_api/planbook_api.dart';

export 'package:auto_route/auto_route.dart';

export 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.cupertino();

  @override
  List<AutoRouteGuard> get guards => [
    AutoRouteGuard.simple(
      (resolver, router) async {
        final user = AppSupabase.user;
        final routeName = resolver.route.name;

        // 如果用户未登录，重定向到登录页面
        if (user == null && routeName != 'SignHomeRoute') {
          await resolver.redirectUntil(const SignHomeRoute(), replace: true);
        } else {
          resolver.next();
        }

        // 如果用户已登录且在登录页面，重定向到主页
        // if (routeName == 'SignHomeRoute') {
        //   await resolver.redirectUntil(const RootRoute(), replace: true);
        //   return;
        // }

        // // 如果用户已登录且在引导页面，检查是否需要重定向
        // if (routeName == 'OnboardingRoute') {
        //   final settingsRepository = resolver.context
        //       .read<SettingsRepository>();
        //   final onboardingCompleted = await settingsRepository
        //       .getOnboardingCompleted();
        //   if (onboardingCompleted) {
        //     await resolver.redirectUntil(const RootRoute(), replace: true);
        //     return;
        //   }
        // }

        // // 其他情况继续导航
        // resolver.next();
      },
    ),
  ];

  AutoRoute _buildModalBottomSheetRoute(
    PageInfo page, {
    List<AutoRoute>? children,
  }) {
    return CustomRoute<void>(
      page: page,
      children: children,
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
            AutoRoute(page: TaskTodayRoute.page, initial: true),
            AutoRoute(page: TaskOverdueRoute.page),
            AutoRoute(page: TaskWeekRoute.page),
            AutoRoute(page: TaskMonthRoute.page),
            AutoRoute(page: TaskTagRoute.page),
          ],
        ),
        AutoRoute(
          page: RootDiscoverRoute.page,
          children: [
            AutoRoute(page: DiscoverJournalRoute.page),
            AutoRoute(page: DiscoverFocusRoute.page),
            AutoRoute(page: DiscoverSummaryRoute.page),
          ],
        ),
        AutoRoute(
          page: RootNoteRoute.page,
          children: [
            AutoRoute(page: NoteTimelineRoute.page),
            AutoRoute(page: NoteWrittenRoute.page),
            AutoRoute(page: NoteGalleryRoute.page),
            AutoRoute(page: NoteTaskRoute.page),
            AutoRoute(page: NoteTagRoute.page),
          ],
        ),
      ],
    ),

    // AutoRoute(page: TaskNewRoute.page),
    _buildModalBottomSheetRoute(TaskNewChildRoute.page),
    _buildModalBottomSheetRoute(TaskNewRoute.page),
    _buildModalBottomSheetRoute(TaskNewRecurrenceEndAtRoute.page),
    _buildModalBottomSheetRoute(TaskDoneRoute.page),

    _buildModalBottomSheetRoute(TaskPickerRoute.page),
    _buildModalBottomSheetRoute(TaskPriorityPickerRoute.page),
    _buildModalBottomSheetRoute(TaskDatePickerRoute.page),
    _buildModalBottomSheetRoute(TaskDurationRoute.page),
    _buildModalBottomSheetRoute(TaskRecurrenceRoute.page),

    _buildModalBottomSheetRoute(
      NoteNewTypeRoute.page,
      // children: [
      //   AutoRoute(page: NoteFocusRoute.page),
      //   AutoRoute(page: NoteSummaryRoute.page),
      // ],
    ),

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
    AutoRoute(page: SettingsTaskRoute.page),
    AutoRoute(page: SettingsBackgroundRoute.page),

    AutoRoute(page: AppPurchasesRoute.page),

    AutoRoute(page: SignHomeRoute.page),

    AutoRoute(page: MinePasswordRoute.page),
    AutoRoute(page: MinePhoneRoute.page),
    AutoRoute(page: MineEmailRoute.page),
    AutoRoute(page: MineProfileRoute.page),
    AutoRoute(page: MineDeleteRoute.page),

    AutoRoute(page: AppActivityRoute.page),
    AutoRoute(page: AppActivityListRoute.page),

    _buildModalBottomSheetRoute(DiscoverJournalPlayRoute.page),
  ];
}
