import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AppEmptyNoteView extends StatelessWidget {
  const AppEmptyNoteView({super.key, this.showSlogan = true, this.top});

  final bool showSlogan;
  final double? top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const imageHeight = 280.0;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: top ?? kToolbarHeight,
        ),
        SvgPicture.asset(
          'assets/images/Summer-Collection.svg',
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
                  context.l10n.noteSlogen,
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
            ),
          ),
        ],
      ],
    );
  }
}
