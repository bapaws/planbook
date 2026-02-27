import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/detail/bloc/task_detail_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';

class TaskDetailNewSubtaskButton extends StatelessWidget {
  const TaskDetailNewSubtaskButton({super.key});

  double get minimumSize => (kMinInteractiveDimension / 4 * 3).floorToDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SliverToBoxAdapter(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.square(minimumSize),
        onPressed: () async {
          final cubit = context.read<TaskDetailBloc>();
          final children = cubit.state.task?.children ?? [];
          final newChildren = await context.router.push(
            TaskNewChildRoute(subTasks: children),
          );
          if (newChildren is! List<TaskEntity> || !context.mounted) {
            return;
          }
          context.read<TaskDetailBloc>().add(
            TaskDetailChildrenChanged(children: newChildren),
          );
        },
        child: Row(
          children: [
            const SizedBox(width: kMinInteractiveDimension / 2 - 1),
            SizedBox(
              height: minimumSize + 2,
              child: VerticalDivider(
                width: 1,
                color: colorScheme.surfaceContainerHighest,
                thickness: 1,
              ),
            ),
            const SizedBox(width: 18),
            Icon(
              FontAwesomeIcons.circlePlus,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.subtask,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: kMinInteractiveDimension / 2),
          ],
        ),
      ),
    );
  }
}
