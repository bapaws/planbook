import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/new/cubit/task_new_cubit.dart';
import 'package:jiffy/jiffy.dart';

class TaskNewDateView extends StatefulWidget {
  const TaskNewDateView({this.date, this.onDateChanged, super.key});

  final Jiffy? date;
  final ValueChanged<Jiffy?>? onDateChanged;

  @override
  State<TaskNewDateView> createState() => _TaskNewDateViewState();
}

class _TaskNewDateViewState extends State<TaskNewDateView> {
  int _index = 0;
  int get index => _index;
  set index(int value) {
    if (value == 0) {
      _selectedDate = Jiffy.now();
      widget.onDateChanged?.call(Jiffy.now());
    } else if (value == 1) {
      final tomorrow = Jiffy.now().add(days: 1);
      _selectedDate = tomorrow;
      widget.onDateChanged?.call(tomorrow);
    } else if (value == 2) {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 150), () {
        final ctx = context;
        if (ctx.mounted) {
          ctx.read<TaskNewCubit>().onFocusChanged(TaskNewFocus.date);
        }
      });
    } else if (value == 3) {
      _selectedDate = null;
      widget.onDateChanged?.call(null);
    }

    if (_index == value) return;
    setState(() {
      _index = value;
    });
  }

  late Jiffy? _selectedDate = widget.date ?? Jiffy.now();
  bool get isOtherDate {
    final now = Jiffy.now();
    return _selectedDate != null &&
        !_selectedDate!.isSame(now, unit: Unit.day) &&
        !_selectedDate!.isSame(now.add(days: 1), unit: Unit.day);
  }

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.date;
    _onDateChanged(_selectedDate);
  }

  void _onDateChanged(Jiffy? date) {
    final now = Jiffy.now();
    if (date == null) {
      _selectedDate = null;
      index = 3;
    } else if (date.isSame(now, unit: Unit.day)) {
      _selectedDate = date;
      index = 0;
    } else if (date.isSame(now.add(days: 1), unit: Unit.day)) {
      _selectedDate = date;
      index = 1;
    } else {
      _selectedDate = date;
      _index = 2;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<TaskNewCubit, TaskNewState>(
      listenWhen: (previous, current) => previous.dueAt != current.dueAt,
      listener: (context, state) {
        _onDateChanged(state.dueAt);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 4;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Row(
                children: [
                  _buildItem(context, 0),
                  _buildItem(context, 1),
                  _buildItem(context, 2),
                  _buildItem(context, 3),
                ],
              ),
              AnimatedPositioned(
                duration: Durations.medium1,
                bottom: 0,
                left: itemWidth * index + (itemWidth - 24) / 2,
                child: Container(
                  height: 4,
                  width: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          this.index = index;
        },
        child: AnimatedDefaultTextStyle(
          duration: Durations.medium1,
          style: textTheme.bodyMedium!.copyWith(
            color: this.index == index
                ? colorScheme.onSurface
                : Colors.grey[400]!,
            fontWeight: this.index == index
                ? FontWeight.bold
                : FontWeight.normal,
          ),
          child: Text(
            this.index == index
                ? _getSelectedTitle(context, index)
                : _getTitle(context, index),
          ),
        ),
      ),
    );
  }

  String _getTitle(BuildContext context, int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.today,
      1 => l10n.tomorrow,
      2 => l10n.otherDate,
      3 => l10n.inbox,
      _ => '',
    };
  }

  String _getSelectedTitle(BuildContext context, int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.today,
      1 => l10n.tomorrow,
      2 =>
        isOtherDate && _selectedDate != null
            ? _selectedDate!.Md
            : l10n.otherDate,
      3 => l10n.inbox,
      _ => '',
    };
  }
}
