import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:uuid/uuid.dart';

@RoutePage()
class TaskNewChildPage extends StatefulWidget {
  const TaskNewChildPage({
    required this.subTasks,
    super.key,
  });

  final List<TaskEntity> subTasks;

  @override
  State<TaskNewChildPage> createState() => _TaskNewChildPageState();
}

class _TaskNewChildPageState extends State<TaskNewChildPage> {
  final _titleController = TextEditingController();
  final _focusNode = FocusNode();

  final List<TaskEntity> _subTasks = [];

  bool _canAdd = false;

  @override
  void initState() {
    super.initState();
    _subTasks.addAll(widget.subTasks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppBar(
              forceMaterialTransparency: true,
              leading: const NavigationBarBackButton(),
              actions: [
                CupertinoButton(
                  onPressed: _pop,
                  child: const Icon(FontAwesomeIcons.check),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    focusNode: _focusNode,
                    controller: _titleController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                      hintText: 'Child Title',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _canAdd = value.trim().isNotEmpty;
                      });
                    },
                    onSubmitted: (value) {
                      final title = value.trim();
                      if (title.isNotEmpty) {
                        setState(() {
                          _subTasks.add(
                            TaskEntity(
                              task: Task(
                                id: const Uuid().v4(),
                                title: title,
                                layer: 1,
                                childCount: 0,
                                order: _subTasks.length,
                                isAllDay: false,
                                alarms: [],
                                createdAt: Jiffy.now(),
                              ),
                            ),
                          );
                        });
                        _titleController.clear();
                        _focusNode.requestFocus(); // 保持焦点继续输入
                      } else {
                        _pop();
                      }
                    },
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.square(kMinInteractiveDimension),
                  onPressed: _canAdd
                      ? () {
                          final title = _titleController.text.trim();
                          if (title.isNotEmpty) {
                            setState(() {
                              _subTasks.add(
                                TaskEntity(
                                  task: Task(
                                    id: const Uuid().v4(),
                                    title: title,
                                    layer: 1,
                                    childCount: 0,
                                    order: _subTasks.length,
                                    isAllDay: false,
                                    alarms: [],
                                    createdAt: Jiffy.now(),
                                  ),
                                ),
                              );
                            });
                            _titleController.clear();
                          }
                        }
                      : null,
                  child: const Icon(FontAwesomeIcons.circlePlus),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    kMinInteractiveDimension *
                    math.min(
                      _subTasks.length,
                      4,
                    ),
              ),
              child: ReorderableListView.builder(
                itemExtent: kMinInteractiveDimension,
                proxyDecorator: (child, index, animation) => child,
                itemBuilder: (context, index) => Row(
                  key: ValueKey(index),
                  children: [
                    const SizedBox(width: 12),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _subTasks[index].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size.square(kMinInteractiveDimension),
                      child: Icon(
                        FontAwesomeIcons.circleMinus,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () {
                        setState(() {
                          _subTasks.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
                itemCount: _subTasks.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    _subTasks.insert(
                      oldIndex < newIndex ? newIndex - 1 : newIndex,
                      _subTasks.removeAt(oldIndex),
                    );
                  });
                },
              ),
            ),
            SizedBox(height: 8 + MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _pop() {
    for (var i = 0; i < _subTasks.length; i++) {
      _subTasks[i] = _subTasks[i].copyWith(
        task: _subTasks[i].task.copyWith(order: i),
      );
    }
    context.router.maybePop(_subTasks);
  }
}
