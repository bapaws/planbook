import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskMonthCalendarView extends StatefulWidget {
  const TaskMonthCalendarView({
    required this.date,
    required this.onDateSelected,
    super.key,
  });

  final Jiffy date;
  final ValueChanged<Jiffy> onDateSelected;

  @override
  State<TaskMonthCalendarView> createState() => _TaskMonthCalendarViewState();
}

class _TaskMonthCalendarViewState extends State<TaskMonthCalendarView> {
  static const int _minYear = 2000;
  static const int _maxYear = 2100;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;

  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.date.year;
    _selectedMonth = widget.date.month;
    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _minYear,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
  }

  @override
  void didUpdateWidget(covariant TaskMonthCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _selectedYear = widget.date.year;
      _selectedMonth = widget.date.month;
      _yearController.jumpToItem(_selectedYear - _minYear);
      _monthController.jumpToItem(_selectedMonth - 1);
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    final newDate = Jiffy.parseFromDateTime(
      DateTime(_selectedYear, _selectedMonth),
    );
    widget.onDateSelected(newDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 年份选择器
          Expanded(
            child: _buildPicker(
              controller: _yearController,
              itemCount: _maxYear - _minYear + 1,
              itemBuilder: (index) {
                final year = _minYear + index;
                final isSelected = year == _selectedYear;
                return Center(
                  child: Text(
                    _getYearName(year),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedYear = _minYear + index;
                });
                _onSelectionChanged();
              },
            ),
          ),
          // 月份选择器
          Expanded(
            child: _buildPicker(
              controller: _monthController,
              itemCount: 12,
              itemBuilder: (index) {
                final month = index + 1;
                final isSelected = month == _selectedMonth;
                return Center(
                  child: Text(
                    _getMonthName(month),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedMonth = index + 1;
                });
                _onSelectionChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Widget Function(int index) itemBuilder,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    final theme = Theme.of(context);

    return CupertinoPicker.builder(
      scrollController: controller,
      itemExtent: 36,
      diameterRatio: 1.5,
      squeeze: 1,
      changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
      ),
      onSelectedItemChanged: onSelectedItemChanged,
      childCount: itemCount,
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }

  String _getYearName(int year) {
    final date = Jiffy.parseFromDateTime(DateTime(year));
    return date.format(pattern: 'y');
  }

  String _getMonthName(int month) {
    // 使用 Jiffy 获取本地化的月份名称
    final date = Jiffy.parseFromDateTime(DateTime(2024, month));
    return date.MMM;
  }
}
