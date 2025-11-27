import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';

const double kRootBottomBarHeight = kToolbarHeight + 8;

@RoutePage()
class RootHomePage extends StatelessWidget {
  const RootHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => RootHomeBloc(
        tagsRepository: context.read(),
      )..add(const RootHomeRequested()),
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
      routes: const [
        RootJournalRoute(),
        RootTaskRoute(),
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
      // transitionBuilder: (context, child, animation) {
      //   return FadeTransition(
      //     opacity: animation,
      //     child: Stack(
      //       alignment: Alignment.bottomCenter,
      //       children: [
      //         child,
      //         const Positioned(
      //           left: 24,
      //           right: 24,
      //           bottom: 22,
      //           child: RootHomeBottomBar(),
      //         ),
      //       ],
      //     ),
      //   );
      // },
    );
  }
}
