import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/launch/bloc/launch_bloc.dart';
import 'package:flutter_planbook/app/launch/view/animated_logo.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';

class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LaunchBloc()
        ..add(const LaunchAuthStateChanged())
        ..add(const LaunchAppLinks()),
      child: const _LaunchPage(),
    );
  }
}

class _LaunchPage extends StatelessWidget {
  const _LaunchPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocBuilder<LaunchBloc, LaunchState>(
      builder: (context, state) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                AnimatedLogo(
                  onStatusChanged: (status) {
                    context.read<LaunchBloc>().add(
                      LaunchAnimationStatusChanged(
                        status: status,
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: kMinInteractiveDimension,
                  child: AnimatedSwitcher(
                    duration: Durations.extralong1,
                    child: state.animationStatus.isForwardOrCompleted
                        ? Text(
                            l10n.appName,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : SizedBox.fromSize(),
                  ),
                ),
                SizedBox(
                  height: kToolbarHeight,
                  child: AnimatedTextKit(
                    totalRepeatCount: 1,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        l10n.slogen,
                        speed: Durations.short1,
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outlineVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    onNextBeforePause: (index, _) {
                      context.read<LaunchBloc>().add(
                        const LaunchAnimationFinished(),
                      );
                    },
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: Durations.long1,
                  child: state.animationStatus.isCompleted
                      ? SvgPicture.asset(
                          'assets/images/welcome.svg',
                          // width: 400,
                          width: 400,
                          height: 300,
                          fit: BoxFit.fitWidth,
                          // height: 300,
                        )
                      : const SizedBox(
                          key: Key('placeholder'),
                          width: 400,
                          height: 300,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
