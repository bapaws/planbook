import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppEmptyTaskView extends StatelessWidget {
  const AppEmptyTaskView({super.key});

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
          'assets/images/Chill-Time.svg',
          width: 280,
          height: 280,
        ),
      ),
    );
  }
}
