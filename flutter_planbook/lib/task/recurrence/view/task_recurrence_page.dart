import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/recurrence/view/task_recurrence_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/recurrence_rule.dart';

@RoutePage()
class TaskRecurrencePage extends StatefulWidget {
  const TaskRecurrencePage({
    this.taskDate,
    this.initialRecurrenceRule,
    super.key,
  });

  final Jiffy? taskDate;
  final RecurrenceRule? initialRecurrenceRule;

  @override
  State<TaskRecurrencePage> createState() => _TaskRecurrencePageState();
}

class _TaskRecurrencePageState extends State<TaskRecurrencePage> {
  late RecurrenceRule? _recurrenceRule =
      widget.initialRecurrenceRule ??
      const RecurrenceRule(frequency: RecurrenceFrequency.daily);

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
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: CupertinoButton(
                onPressed: () {
                  context.router.maybePop();
                },
                child: Text(context.l10n.noRepeat),
              ),
              actions: [
                CupertinoButton(
                  onPressed: () {
                    context.router.maybePop(_recurrenceRule);
                  },
                  child: const Icon(FontAwesomeIcons.check),
                ),
              ],
            ),
            TaskRecurrenceView(
              onRecurrenceRuleChanged: (value) {
                _recurrenceRule = value;
              },
              taskDate: widget.taskDate,
              initialRecurrenceRule: _recurrenceRule,
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
