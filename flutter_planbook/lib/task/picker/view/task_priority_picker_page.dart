import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/database/task_priority.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class TaskPriorityPickerPage extends StatelessWidget {
  const TaskPriorityPickerPage({
    required this.selectedPriority,
    this.onSelected,
    super.key,
  });

  final TaskPriority selectedPriority;
  final ValueChanged<TaskPriority>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight:
            kToolbarHeight +
            kToolbarHeight * TaskPriority.values.length +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        image: const DecorationImage(
          image: AssetImage('assets/images/bg_tile.png'),
          repeat: ImageRepeat.repeat,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          AppBar(
            forceMaterialTransparency: true,
            title: Text(context.l10n.priority),
            leading: const NavigationBarBackButton(),
          ),
          for (final priority in TaskPriority.values.reversed) ...[
            _buildPriorityItem(context, priority),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityItem(BuildContext context, TaskPriority priority) {
    final colorScheme = priority.getColorScheme(context);
    return CupertinoButton(
      child: Row(
        children: [
          AppIcon(
            FontAwesomeIcons.solidFlag,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            switch (priority) {
              TaskPriority.high => context.l10n.importantUrgent,
              TaskPriority.medium => context.l10n.importantNotUrgent,
              TaskPriority.low => context.l10n.urgentUnimportant,
              TaskPriority.none => context.l10n.notUrgentUnimportant,
            },
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const Spacer(),
          if (priority == selectedPriority)
            Icon(
              FontAwesomeIcons.check,
              color: colorScheme.onSurface,
              size: 16,
            ),
        ],
      ),
      onPressed: () {
        onSelected?.call(priority);
        context.router.maybePop(priority);
      },
    );
  }
}
