import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TaskWeekHeader extends StatelessWidget {
  const TaskWeekHeader({
    required this.title,
    required this.colorScheme,
    this.subtitle,
    this.titleLeading,
    this.isToday = false,
    this.taskCount,
    this.onAddTask,
    this.action,
    this.onTap,
    this.showDropdownAffordance = false,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// 标题 chip 内、文字左侧的图标（如收集箱/标签/日期）。
  final Widget? titleLeading;
  final bool isToday;
  final ColorScheme colorScheme;
  final int? taskCount;

  final VoidCallback? onAddTask;

  /// 覆盖默认加号按钮，例如第一格的思维导图入口。
  final Widget? action;
  final VoidCallback? onTap;

  /// 标题 chip 右侧显示下拉箭头（第一格切换菜单）。
  final bool showDropdownAffordance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = Row(
      children: [
        const SizedBox(width: 8, height: 28),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (titleLeading != null) ...[
                          IconTheme(
                            data: IconThemeData(
                              size: theme.textTheme.bodySmall?.fontSize ?? 12,
                              color: isToday
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimaryContainer,
                            ),
                            child: titleLeading!,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        if (showDropdownAffordance) ...[
                          const SizedBox(width: 2),
                          Icon(
                            CupertinoIcons.chevron_down,
                            size: 10,
                            color: isToday
                                ? colorScheme.onPrimary
                                : colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 6),
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (taskCount != null)
          Text(
            '$taskCount',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (action != null)
          action!
        else if (onAddTask != null)
          CupertinoButton(
            onPressed: onAddTask,
            sizeStyle: CupertinoButtonSize.small,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size.square(28),
            child: FaIcon(
              FontAwesomeIcons.plus,
              size: 14,
              color: colorScheme.primary,
            ),
          )
        else
          const SizedBox(width: 8, height: 28),
      ],
    );

    if (onTap == null) return header;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: header,
    );
  }
}
