import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
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
          create: (context) => SignHomeCubit(
            usersRepository: context.read(),
          )..onInitialized(),
        ),
        BlocProvider(
          create: (context) => SignInCubit(
            usersRepository: context.read(),
          ),
        ),
      ],
      child: BlocListener<SignHomeCubit, SignHomeState>(
        listenWhen: (previous, current) =>
            previous.authResponse != current.authResponse,
        listener: (context, state) {
          if (state.authResponse == null) return;
          final isPremium = context.read<AppPurchasesBloc>().state.isPremium;
          context.router.replaceAll([
            const RootHomeRoute(),
            if (!isPremium) const AppPurchasesRoute(),
          ]);
        },
        child: const _SignHomePage(),
      ),
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
                      key: ValueKey(state.status),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(96),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          36,
                          24,
                          query.padding.bottom + 8,
                        ),
                        child: switch (state.status) {
                          SignHomeStatus.welcome => const SignWelcomePage(),
                          SignHomeStatus.signInWithCode =>
                            const SignInCodePage(),
                          SignHomeStatus.signInWithEmail =>
                            const SignInCodePage(
                              status: SignHomeStatus.signInWithEmail,
                            ),
                          SignHomeStatus.signInWithPassword =>
                            const SignInPasswordPage(),
                          SignHomeStatus.signInWithPhone =>
                            const SignInCodePage(
                              status: SignHomeStatus.signInWithPhone,
                            ),
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
