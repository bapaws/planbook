import 'package:flutter/material.dart';
import 'package:flutter_planbook/tag/new/view/tag_new_button.dart';
import 'package:flutter_svg/svg.dart';

class TagListEmptyView extends StatelessWidget {
  const TagListEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: double.infinity,
          height: 16,
        ),
        SvgPicture.asset(
          'assets/images/empty.svg',
          width: 200,
          height: 200,
        ),
        const SizedBox(width: 180, child: TagNewButton()),
      ],
    );
  }
}
