import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/new/cubit/task_new_cubit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart' hide Column;

class TaskNewPriorityBottomView extends StatelessWidget {
  const TaskNewPriorityBottomView({
    required this.selectedPriority,
    required this.onPriorityChanged,
    super.key,
  });

  final TaskPriority selectedPriority;
  final ValueChanged<TaskPriority> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mediaQuery = MediaQuery.of(context);

    return BlocSelector<TaskNewCubit, TaskNewState, TaskPriority>(
      selector: (state) => state.priority,
      builder: (context, selectedPriority) {
        return Container(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 16 + mediaQuery.padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildQuadrant(
                            context: context,
                            label: l10n.importantUrgent,
                            priority: TaskPriority.high,
                            selectedPriority: selectedPriority,
                          ),
                          _buildQuadrant(
                            context: context,
                            label: l10n.urgentUnimportant,
                            priority: TaskPriority.low,
                            selectedPriority: selectedPriority,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildQuadrant(
                            context: context,
                            label: l10n.importantNotUrgent,
                            priority: TaskPriority.medium,
                            selectedPriority: selectedPriority,
                          ),
                          _buildQuadrant(
                            context: context,
                            label: l10n.notUrgentUnimportant,
                            priority: TaskPriority.none,
                            selectedPriority: selectedPriority,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuadrant({
    required BuildContext context,
    required String label,
    required TaskPriority priority,
    required TaskPriority selectedPriority,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = priority == selectedPriority;
    final quadrantColor = priority.getColorScheme(context).primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<TaskNewCubit>().onPriorityChanged(priority);
          FocusScope.of(context).requestFocus();
          Future.delayed(const Duration(milliseconds: 150), () {
            if (context.mounted) {
              context.read<TaskNewCubit>().onFocusChanged(
                TaskNewFocus.title,
              );
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: priority.isImportant
                  ? BorderSide.none
                  : BorderSide(color: colorScheme.outline),
              bottom: !priority.isImportant
                  ? BorderSide.none
                  : BorderSide(color: colorScheme.outline),
              left: priority.isUrgent
                  ? BorderSide.none
                  : BorderSide(color: colorScheme.outline),
              right: !priority.isUrgent
                  ? BorderSide.none
                  : BorderSide(color: colorScheme.outline),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              if (isSelected) ...[
                Positioned(
                  top: !priority.isImportant ? 0 : null,
                  left: priority.isUrgent ? null : 0,
                  right: !priority.isUrgent ? null : 0,
                  bottom: priority.isImportant ? 0 : null,
                  child: Icon(
                    FontAwesomeIcons.solidFlag,
                    size: 16,
                    color: quadrantColor,
                  ),
                ),
              ],
              AnimatedDefaultTextStyle(
                duration: Durations.medium1,
                style: textTheme.titleSmall!.copyWith(
                  color: isSelected ? quadrantColor : colorScheme.outline,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
