import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:jiffy/jiffy.dart';

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
            context.read<AppBloc>().add(AppLaunched(l10n: l10n));
            FlutterNativeSplash.remove();

            /// Trigger app purchases requested to get store products
            context.read<AppPurchasesBloc>();

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
      child: const _RootHomePage(),
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
