import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AppEmptyTaskView extends StatelessWidget {
  const AppEmptyTaskView({super.key, this.showSlogan = true});
  final bool showSlogan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const imageHeight = 280.0;
    final query = MediaQuery.of(context);
    final bottom =
        (query.size.height -
            query.padding.vertical -
            imageHeight -
            kToolbarHeight) /
        2;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: double.infinity),
        SvgPicture.asset(
          'assets/images/Chill-Time.svg',
          width: imageHeight,
          height: imageHeight,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),

        if (showSlogan) ...[
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
                  context.l10n.taskSlogen,
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
            ),
          ),
          SizedBox(height: bottom),
        ],
      ],
    );
  }
}
