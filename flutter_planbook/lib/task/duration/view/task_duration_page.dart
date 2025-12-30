import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/duration/model/task_duration_entity.dart';
import 'package:flutter_planbook/task/duration/view/task_duration_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';

@RoutePage()
class TaskDurationPage extends StatefulWidget {
  const TaskDurationPage({
    this.startAt,
    this.endAt,
    this.isAllDay = true,
    super.key,
  });

  final Jiffy? startAt;
  final Jiffy? endAt;
  final bool isAllDay;

  @override
  State<TaskDurationPage> createState() => _TaskDurationPageState();
}

class _TaskDurationPageState extends State<TaskDurationPage> {
  late TaskDurationEntity _entity;

  @override
  void initState() {
    final now = Jiffy.now();
    Jiffy startAt;
    Jiffy endAt;
    if (widget.isAllDay) {
      startAt = widget.startAt ?? now.startOf(Unit.day);
      endAt = widget.endAt ?? startAt.endOf(Unit.day);
    } else {
      startAt = widget.startAt ?? now.startOf(Unit.hour).add(hours: 1);
      endAt = widget.endAt ?? startAt.add(hours: 1);
    }
    _entity = TaskDurationEntity(
      isAllDay: widget.isAllDay,
      startAt: startAt,
      endAt: endAt,
    );
    super.initState();
  }

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
              // leadingWidth: 120,
              automaticallyImplyLeading: false,
              // titleSpacing: 0,
              leadingWidth: 150,
              leading: CupertinoButton(
                alignment: Alignment.centerLeft,
                onPressed: () {
                  context.router.maybePop(
                    TaskDurationEntity(
                      startAt: _entity.startAt,
                      isAllDay: true,
                    ),
                  );
                },
                child: Text(context.l10n.thatDay),
              ),
              actions: [
                CupertinoButton(
                  onPressed: () {
                    context.router.maybePop(_entity);
                  },
                  child: const Icon(FontAwesomeIcons.check),
                ),
              ],
            ),
            TaskDurationView(
              entity: _entity,
              onValueChanged: (value) {
                _entity = value;
              },
            ),
            SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
