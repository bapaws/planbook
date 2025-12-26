import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/model/recurrence_rule_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/database/recurrence_rule.dart';

class TaskRecurrenceRuleTagView extends StatelessWidget {
  const TaskRecurrenceRuleTagView({
    required this.recurrenceRule,
    this.colorScheme,
    super.key,
  });

  final RecurrenceRule recurrenceRule;
  final ColorScheme? colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colorScheme?.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FontAwesomeIcons.arrowsRotate,
            size: 12,
            color: colorScheme?.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            recurrenceRule.getTitle(context.l10n),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme?.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
