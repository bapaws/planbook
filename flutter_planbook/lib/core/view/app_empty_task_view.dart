import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AppEmptyTaskView extends StatelessWidget {
  const AppEmptyTaskView({
    super.key,
    this.imageName = 'assets/images/Chill-Time.svg',
    this.title,
  });
  final String? imageName;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const imageHeight = 280.0;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: title != null ? kToolbarHeight : 0,
        ),
        if (imageName != null)
          if (imageName!.endsWith('.svg'))
            SvgPicture.asset(
              imageName!,
              width: imageHeight,
              height: imageHeight,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            )
          else
            Image.asset(
              imageName!,
              width: imageHeight,
              height: imageHeight,
            ),

        if (title != null) ...[
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
                  title!,
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
