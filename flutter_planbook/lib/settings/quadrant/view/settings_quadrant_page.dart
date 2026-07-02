import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/quadrant/cubit/settings_quadrant_cubit.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class SettingsQuadrantPage extends StatelessWidget {
  const SettingsQuadrantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsQuadrantCubit(
        settingsRepository: context.read(),
        usersRepository: context.read(),
      )..onRequested(),
      child: const _SettingsQuadrantPage(),
    );
  }
}

class _SettingsQuadrantPage extends StatelessWidget {
  const _SettingsQuadrantPage();

  static const _rowHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      constraints: BoxConstraints(
        maxHeight:
            kToolbarHeight +
            _rowHeight * TaskPriority.values.length +
            mediaQuery.padding.bottom +
            mediaQuery.viewInsets.bottom +
            16,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          AppBar(
            forceMaterialTransparency: true,
            title: Text(context.l10n.quadrantCustomize),
            leading: const NavigationBarCloseButton(),
          ),
          Expanded(
            child: BlocBuilder<SettingsQuadrantCubit, SettingsQuadrantState>(
              builder: (context, state) {
                return ListView(
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: 8 + mediaQuery.viewInsets.bottom,
                  ),
                  children: [
                    for (final priority in TaskPriority.values.reversed)
                      _QuadrantConfigRow(
                        key: ValueKey(priority),
                        priority: priority,
                        config: state.configOf(priority),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuadrantConfigRow extends StatefulWidget {
  const _QuadrantConfigRow({
    required this.priority,
    required this.config,
    super.key,
  });

  final TaskPriority priority;
  final QuadrantConfigEntity config;

  @override
  State<_QuadrantConfigRow> createState() => _QuadrantConfigRowState();
}

class _QuadrantConfigRowState extends State<_QuadrantConfigRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.config.name ?? '');
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _QuadrantConfigRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部（如恢复默认）改变了名称时同步到输入框
    final name = widget.config.name ?? '';
    if (!_focusNode.hasFocus && name != _controller.text) {
      _controller.text = name;
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _commitName();
    }
  }

  void _commitName() {
    context.read<SettingsQuadrantCubit>().onNameChanged(
      widget.priority,
      _controller.text,
    );
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = widget.priority.getColorScheme(context);
    final defaultName = widget.priority.getTitle(context.l10n);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.priority.value}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                _commitName();
                _focusNode.unfocus();
              },
              decoration: InputDecoration(
                hintText: defaultName,
                border: InputBorder.none,
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (!widget.config.isDefault)
            CupertinoButton(
              padding: const EdgeInsets.only(left: 8),
              minimumSize: const Size.square(32),
              onPressed: () {
                _focusNode.unfocus();
                context.read<SettingsQuadrantCubit>().onResetQuadrant(
                  widget.priority,
                );
              },
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 20,
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}
