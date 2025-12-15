import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppNoteEmptyView extends StatelessWidget {
  const AppNoteEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          bottom:
              24 +
              kBottomNavigationBarHeight +
              MediaQuery.of(context).padding.bottom,
        ),
        child: SvgPicture.asset(
          'assets/images/Summer-Collection.svg',
          width: 280,
          height: 280,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
