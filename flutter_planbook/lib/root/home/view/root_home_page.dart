import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:planbook_api/entity/task_entity.dart';

const double kRootBottomBarHeight = kToolbarHeight + 8;

@RoutePage()
class RootHomePage extends StatelessWidget {
  const RootHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (context) => RootHomeBloc(
            tagsRepository: context.read(),
          )..add(const RootHomeRequested()),
        ),
        BlocProvider(
          create: (context) =>
              RootTaskBloc(
                  tasksRepository: context.read(),
                )
                ..add(
                  const RootTaskTaskCountRequested(mode: TaskListMode.inbox),
                )
                ..add(
                  const RootTaskTaskCountRequested(mode: TaskListMode.today),
                )
                ..add(
                  const RootTaskTaskCountRequested(mode: TaskListMode.overdue),
                ),
        ),
        BlocProvider(
          create: (context) => TaskTodayBloc(),
        ),
      ],
      child: BlocListener<RootHomeBloc, RootHomeState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          context.read<AppBloc>().add(AppLaunched(l10n: context.l10n));
          FlutterNativeSplash.remove();
        },
        child: const _RootHomePage(),
      ),
    );
  }
}

class _RootHomePage extends StatelessWidget {
  const _RootHomePage();

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: [
        RootTaskRoute(),
        const RootJournalRoute(),
        const RootNoteRoute(),
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
