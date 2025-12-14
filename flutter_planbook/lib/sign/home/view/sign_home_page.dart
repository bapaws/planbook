import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/sign/home/cubit/sign_home_cubit.dart';
import 'package:flutter_planbook/sign/home/view/sign_home_slogan_view.dart';
import 'package:flutter_planbook/sign/in/cubit/sign_in_cubit.dart';
import 'package:flutter_planbook/sign/in/view/sign_in_code_page.dart';
import 'package:flutter_planbook/sign/in/view/sign_in_password_page.dart';
import 'package:flutter_planbook/sign/password/view/sign_password_page.dart';
import 'package:flutter_planbook/sign/up/view/sign_up_page.dart';
import 'package:flutter_planbook/sign/welcome/view/sign_welcome_page.dart';
import 'package:planbook_core/app/app_scaffold.dart';

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
    final l10n = context.l10n;
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
            // appBar: AppBar(
            //   leading: const NavigationBarCloseButton(),
            //   title: Text(context.l10n.appName.toUpperCase()),
            //   forceMaterialTransparency: true,
            // ),
            body: Stack(
              children: [
                // SizedBox(height: query.padding.top),
                Positioned(
                  top: query.padding.top,
                  left: 0,
                  right: 0,
                  bottom: 400 + query.padding.bottom,
                  child: const SignHomeSloganView(),
                ),

                // 底部白色卡片
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(96),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: Durations.medium2,
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
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
