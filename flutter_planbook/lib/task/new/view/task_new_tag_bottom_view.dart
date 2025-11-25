import 'package:flutter/material.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_view.dart';

class TaskNewTagBottomView extends StatelessWidget {
  const TaskNewTagBottomView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: TagListView(showAddButton: true),
    );
  }
}
