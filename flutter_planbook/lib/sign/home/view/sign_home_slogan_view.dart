import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SignHomeSloganView extends StatelessWidget {
  const SignHomeSloganView({super.key});

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // SizedBox(height: query.padding.top / 2),
        // primary color:fill="#BCF0B4"
        Flexible(
          child: SvgPicture.asset(
            'assets/images/sign-in-bg.svg',
            fit: BoxFit.fitHeight,
          ),
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
                context.l10n.slogen,
                speed: const Duration(milliseconds: 100),
              ),
            ],
            repeatForever: true,
            displayFullTextOnTap: true,
            stopPauseOnTap: true,
          ),
        ),
      ],
    );
  }
}
