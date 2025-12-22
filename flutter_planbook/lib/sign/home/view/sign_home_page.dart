import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/sign/home/cubit/sign_home_cubit.dart';
import 'package:flutter_planbook/sign/home/view/sign_home_slogan_view.dart';
import 'package:flutter_planbook/sign/in/cubit/sign_in_cubit.dart';
import 'package:flutter_planbook/sign/in/view/sign_in_code_page.dart';
import 'package:flutter_planbook/sign/in/view/sign_in_password_page.dart';
import 'package:flutter_planbook/sign/password/view/sign_password_page.dart';
import 'package:flutter_planbook/sign/up/view/sign_up_page.dart';
import 'package:flutter_planbook/sign/welcome/view/sign_welcome_page.dart';

@RoutePage()
class SignHomePage extends StatelessWidget {
  const SignHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SignHomeCubit()..onInitialized(),
        ),
        BlocProvider(
          create: (context) => SignInCubit(
            usersRepository: context.read(),
          ),
        ),
      ],
      child: const _SignHomePage(),
    );
  }
}

class _SignHomePage extends StatelessWidget {
  const _SignHomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = MediaQuery.of(context);
    return BlocBuilder<SignHomeCubit, SignHomeState>(
      builder: (context, state) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: AppScaffold(
            body: Stack(
              children: [
                Positioned(
                  top: (query.size.height - 420 - 320) / 2,
                  left: 0,
                  right: 0,
                  child: const SignHomeSloganView(),
                ),

                // 底部白色卡片
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedSwitcher(
                    duration: Durations.medium2,
                    transitionBuilder: (child, animation) => SizeTransition(
                      sizeFactor: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(96),
                        ),
                      ),
                      child: Padding(
                        key: ValueKey(state.status),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          36,
                          24,
                          query.padding.bottom + 8,
                        ),
                        child: switch (state.status) {
                          SignHomeStatus.welcome => const SignWelcomePage(),
                          SignHomeStatus.signInWithPassword =>
                            const SignInPasswordPage(),
                          SignHomeStatus.signInWithPhone =>
                            const SignInPhonePage(),
                          SignHomeStatus.signUp => const SignUpPage(),
                          SignHomeStatus.forgotPassword =>
                            const SignPasswordPage(),
                        },
                      ),
                    ),
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
