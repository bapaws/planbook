import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:planbook_repository/planbook_repository.dart';

class NoteGalleryCalendarView extends StatefulWidget {
  const NoteGalleryCalendarView({
    required this.date,
    required this.onDateSelected,
    super.key,
  });

  final Jiffy date;
  final ValueChanged<Jiffy> onDateSelected;

  @override
  State<NoteGalleryCalendarView> createState() =>
      _NoteGalleryCalendarViewState();
}

class _NoteGalleryCalendarViewState extends State<NoteGalleryCalendarView> {
  static const int _minYear = 2000;
  static const int _maxYear = 2100;

  late FixedExtentScrollController _yearController;

  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.date.year;
    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _minYear,
    );
  }

  @override
  void didUpdateWidget(covariant NoteGalleryCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _selectedYear = widget.date.year;
      _yearController.jumpToItem(_selectedYear - _minYear);
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    final newDate = Jiffy.parseFromDateTime(
      DateTime(_selectedYear).toLocal(),
    );
    widget.onDateSelected(newDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
}
