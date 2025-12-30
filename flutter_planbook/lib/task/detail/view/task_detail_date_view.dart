import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/detail/view/task_detail_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TaskDetailDateView extends StatelessWidget {
  const TaskDetailDateView({
    required this.title,
    required this.formattedDate,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String? formattedDate;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TaskDetailSliverTile(
      onPressed: onPressed,
      leading: AppIcon(
        FontAwesomeIcons.solidCalendarDays,
        backgroundColor: theme.colorScheme.tertiaryContainer,
        foregroundColor: theme.colorScheme.tertiary,
      ),
      title: title,
      trailing: Text(
        formattedDate ?? context.l10n.inbox,
      ),
    );
  }
}
