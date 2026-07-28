import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_bloc_provider.dart';
import 'package:flutter_planbook/task/time_block/bloc/task_time_block_bloc.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_demo_data.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_view.dart';
import 'package:jiffy/jiffy.dart';

class TaskTimeBlockPage extends StatelessWidget {
  const TaskTimeBlockPage({
    required this.date,
    super.key,
  });

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppPurchasesBloc, AppPurchasesState, bool>(
      selector: (state) => state.isPremium,
      builder: (context, isPremium) {
        // 会员使用真实任务数据
        if (isPremium) {
          return TaskListBlocProvider(
            key: ValueKey('time-block-$date'),
            requestEvent: () => TaskListDayAllRequested(date: date),
            child: BlocProvider(
              create: (context) {
                final tasks = context.read<TaskListBloc>().state.tasks;
                return TaskTimeBlockBloc(date: date)
                  ..add(const TaskTimeBlockStarted())
                  ..add(TaskTimeBlockTasksUpdated(tasks));
              },
              child: BlocListener<TaskListBloc, TaskListState>(
                listenWhen: (previous, current) =>
                    previous.tasks != current.tasks,
                listener: (context, state) {
                  context.read<TaskTimeBlockBloc>().add(
                    TaskTimeBlockTasksUpdated(state.tasks),
                  );
                },
                child: const TaskTimeBlockView(),
              ),
            ),
          );
        }

        // 非会员展示演示数据（无 TaskListBloc，View 必须 isDemo: true 跳过删除监听）
        // l10n 必须在 create 外读取：create 生命周期不能 listen InheritedWidget
        final demoTasks = buildTaskTimeBlockDemoTasks(date, context.l10n);
        return BlocProvider(
          key: ValueKey('time-block-demo-$date'),
          create: (_) => TaskTimeBlockBloc(date: date, isDemo: true)
            ..add(const TaskTimeBlockStarted())
            ..add(TaskTimeBlockTasksUpdated(demoTasks)),
          child: const TaskTimeBlockView(isDemo: true),
        );
      },
    );
  }
}
