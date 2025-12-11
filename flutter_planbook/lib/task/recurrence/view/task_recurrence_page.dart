import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/recurrence/view/task_recurrence_view.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/recurrence_rule.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class TaskRecurrencePage extends StatelessWidget {
  const TaskRecurrencePage({
    required this.onRecurrenceRuleChanged,
    this.taskDate,
    this.initialRecurrenceRule,
    super.key,
  });

  final Jiffy? taskDate;
  final RecurrenceRule? initialRecurrenceRule;
  final ValueChanged<RecurrenceRule?> onRecurrenceRuleChanged;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.vertical,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppBar(
              leading: const NavigationBarBackButton(),
              actions: [
                CupertinoButton(
                  onPressed: () {
                    onRecurrenceRuleChanged(null);
                    context.pop();
                  },
                  child: Text(context.l10n.noRepeat),
                ),
              ],
            ),
            TaskRecurrenceView(
              onRecurrenceRuleChanged: onRecurrenceRuleChanged,
              taskDate: taskDate,
              initialRecurrenceRule: initialRecurrenceRule,
            ),
            SizedBox(
              height: 16 + MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      ),
    );
  }
}
