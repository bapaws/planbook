import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/duration/view/task_duration_view.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class TaskDurationPage extends StatelessWidget {
  const TaskDurationPage({
    required this.startAt,
    required this.endAt,
    required this.isAllDay,
    required this.onIsAllDayChanged,
    required this.onStartAtChanged,
    required this.onEndAtChanged,
    super.key,
  });

  final Jiffy? startAt;
  final Jiffy? endAt;
  final bool isAllDay;
  final ValueChanged<bool> onIsAllDayChanged;
  final ValueChanged<Jiffy?> onStartAtChanged;
  final ValueChanged<Jiffy?> onEndAtChanged;

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
                    onIsAllDayChanged(true);
                    context.router.maybePop();
                  },
                  child: Text(context.l10n.allDay),
                ),
              ],
            ),
            TaskDurationView(
              startAt: startAt,
              endAt: endAt,
              isAllDay: isAllDay,
              onIsAllDayChanged: onIsAllDayChanged,
              onStartAtChanged: onStartAtChanged,
              onEndAtChanged: onEndAtChanged,
            ),
            SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
