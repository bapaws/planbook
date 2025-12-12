import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/sign/home/cubit/sign_home_cubit.dart';
import 'package:flutter_planbook/sign/in/cubit/sign_in_cubit.dart';
import 'package:flutter_planbook/sign/in/view/sign_in_code_page.dart';
import 'package:flutter_planbook/sign/in/view/sign_in_password_page.dart';
import 'package:flutter_planbook/sign/password/view/sign_password_page.dart';
import 'package:flutter_planbook/sign/up/view/sign_up_page.dart';
import 'package:flutter_planbook/sign/welcome/view/sign_welcome_page.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return BlocBuilder<SignHomeCubit, SignHomeState>(
      builder: (context, state) {
        return AppScaffold(
          // appBar: AppBar(
          //   leading: const NavigationBarCloseButton(),
          //   title: Text(context.l10n.appName.toUpperCase()),
          //   forceMaterialTransparency: true,
          // ),
          body: Column(
            children: [
              const Spacer(),
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              // primary color:fill="#BCF0B4"
              SvgPicture.asset(
                'assets/images/sign-in-bg.svg',
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
              DefaultTextStyle(
                textAlign: TextAlign.center,
                style: GoogleFonts.zcoolKuaiLe(
                  textStyle: theme.textTheme.titleLarge!.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TyperAnimatedText(
                      l10n.slogen,
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  repeatForever: true,
                  displayFullTextOnTap: true,
                  stopPauseOnTap: true,
                ),
              ),

              const Spacer(),

              // 底部白色卡片
              Container(
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
                      MediaQuery.of(context).padding.bottom + 8,
                    ),
                    child: switch (state.status) {
                      SignHomeStatus.welcome => const SignWelcomePage(),
                      SignHomeStatus.signInWithPassword =>
                        const SignInPasswordPage(),
                      SignHomeStatus.signInWithPhone => const SignInPhonePage(),
                      SignHomeStatus.signUp => const SignUpPage(),
                      SignHomeStatus.forgotPassword => const SignPasswordPage(),
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
