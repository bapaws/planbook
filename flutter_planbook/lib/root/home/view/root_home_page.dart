import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:planbook_repository/planbook_repository.dart';

const double kRootBottomBarHeight = kToolbarHeight;

@RoutePage()
class RootHomePage extends StatelessWidget {
  const RootHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (context) {
            /// Trigger app launched to create default tags and sample tasks
            context.read<AppBloc>()
              ..add(AppLaunched(l10n: l10n))
              ..add(const AppApkVersionRequested());
            FlutterNativeSplash.remove();

            /// Trigger app purchases requested to get store products
            context.read<AppPurchasesBloc>();

            /// 注入通知渠道的国际化文案；进入主页后滚动补 schedule
            AlarmNotificationService.instance.setChannelStrings(
              name: l10n.taskReminderChannelName,
              description: l10n.taskReminderChannelDescription,
            );
            Future.microtask(
              context.read<TasksRepository>().rescheduleAllRecurringAlarms,
            );

            return RootHomeBloc(
              tagsRepository: context.read(),
            )..add(const RootHomeRequested());
          },
        ),

        BlocProvider(
          create: (context) =>
              RootTaskBloc(
                  tasksRepository: context.read(),
                  settingsRepository: context.read(),
                )
                ..add(const RootTaskCountRequested())
                ..add(const RootTaskPriorityStyleRequested()),
        ),
        // Add task
        BlocProvider(
          create: (context) => TaskTodayBloc(
            tasksRepository: context.read(),
            notesRepository: context.read(),
          )..add(TaskTodayDateSelected(date: Jiffy.now())),
        ),
        BlocProvider(
          create: (context) => RootDiscoverBloc(),
        ),
      ],
      child: BlocListener<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            previous.apkHasNewVersion != current.apkHasNewVersion &&
            current.apkHasNewVersion,
        listener: (context, state) {
          showApkDownloadDialog(context);
        },
        child: const _RootHomePage(),
      ),
    );
  }

  void showApkDownloadDialog(BuildContext context) {
    if (!AppPurchases.instance.isAndroidChina) return;
    final bloc = context.read<AppBloc>();
    final newVersion = bloc.state.apkVersion;
    if (newVersion == null) return;
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('新版本通知'),
        content: Text('新版本 $newVersion 已发布，立即下载安装'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(context.l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              bloc.add(AppApkDownloadRequested(l10n: context.l10n));
              Navigator.of(context).pop();
            },
            child: const Text('立即下载'),
          ),
        ],
      ),
    );
  }
}

class _RootHomePage extends StatelessWidget {
  const _RootHomePage();

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        RootTaskRoute(),
        RootDiscoverRoute(),
        RootNoteRoute(),
      ],
      builder: (context, child) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            child,
            const Positioned(
              left: 24,
              right: 24,
              bottom: 22,
              child: RootHomeBottomBar(),
            ),
          ],
        );
      },
      transitionBuilder: (context, child, animation) {
        return FadeTransition(
          opacity: animation,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              child,
              const Positioned(
                left: 24,
                right: 24,
                bottom: 22,
                child: RootHomeBottomBar(),
              ),
            ],
          ),
        );
      },
    );
  }
}
