import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

const double kMonthlyMindMapExpandedRadius = 320;
const double kWeeklyMindMapExpandedRadius = 108;
const double kDailyMindMapExpandedRadius = 40;

const double kYearlyNodeExpandedRadius = 200;
const double kMonthlyNodeExpandedRadius = 100;
const double kWeeklyNodeExpandedRadius = 44;
const double kDailyNodeExpandedRadius = 28;

const double kMonthlyMindMapRadius = 190;
const double kWeeklyMindMapRadius = 328;
const double kDailyMindMapRadius = 460;

const double kYearlyNodeRadius = 128;
const double kMonthlyNodeRadius = 75;
const double kWeeklyNodeRadius = 64;
const double kDailyNodeRadius = 56;

final class NoteMindMapEntity extends Equatable {
  const NoteMindMapEntity({
    required this.date,
    required this.type,
    this.note,
    this.children = const [],
    this.isSelected = false,
    this.expandedAngle = 0,
    this.angle = 0,
    this.expandedOffset = Offset.zero,
    this.selectedOffset = Offset.zero,
    this.unselectedOffset = Offset.zero,
    this.normalOffset = Offset.zero,
  });

  final Jiffy date;
  final NoteType type;
  final Note? note;
  final List<NoteMindMapEntity> children;

  final Offset expandedOffset;

  final Offset selectedOffset;
  final Offset unselectedOffset;

  final Offset normalOffset;

  Offset getOffset({bool isExpanded = false}) {
    if (isExpanded) return expandedOffset;
    if (isSelected) return selectedOffset;
    // if (isParentSelected) return unselectedOffset;
    return normalOffset;
  }

  final double expandedAngle; // 扩展角度
  final double angle; // 普通角度

  final bool isSelected;

  String get key => '${date.format(pattern: 'yyyy-MM-dd')}-${type.name}';

  ColorScheme getColorScheme(BuildContext context) {
    if (type.isYearly) {
      return type.isSummary ? context.greenColorScheme : context.redColorScheme;
    }
    final colorScheme = switch (date.month) {
      1 => context.blueColorScheme,
      2 => context.amberColorScheme,
      3 => context.yellowColorScheme,
      4 => context.pinkColorScheme,
      5 => context.orangeColorScheme,
      6 => context.brownColorScheme,
      7 => context.indigoColorScheme,
      8 => context.tealColorScheme,
      9 => context.cyanColorScheme,
      10 => context.limeColorScheme,
      11 => context.purpleColorScheme,
      12 => context.greyColorScheme,
      _ => context.greyColorScheme,
    };
    return colorScheme;
    // return switch (type) {
    //   NoteType.yearlyFocus || NoteType.yearlySummary => context.redColorScheme,
    //   NoteType.monthlyFocus ||
    //   NoteType.monthlySummary => context.blueColorScheme,
    //   NoteType.weeklyFocus ||
    //   NoteType.weeklySummary => context.amberColorScheme,
    //   NoteType.dailyFocus || NoteType.dailySummary => context.greenColorScheme,
    //   _ => context.greyColorScheme,
    // };
  }

  double get expandedSize => switch (type) {
    NoteType.yearlyFocus || NoteType.yearlySummary => kYearlyNodeExpandedRadius,
    NoteType.monthlyFocus ||
    NoteType.monthlySummary => kMonthlyNodeExpandedRadius,
    NoteType.weeklyFocus || NoteType.weeklySummary => kWeeklyNodeExpandedRadius,
    NoteType.dailyFocus || NoteType.dailySummary => kDailyNodeExpandedRadius,
    _ => throw UnimplementedError(),
  };
  double get size => switch (type) {
    NoteType.yearlyFocus || NoteType.yearlySummary => kYearlyNodeRadius,
    NoteType.monthlyFocus || NoteType.monthlySummary => kMonthlyNodeRadius,
    NoteType.weeklyFocus || NoteType.weeklySummary => kWeeklyNodeRadius,
    NoteType.dailyFocus || NoteType.dailySummary => kDailyNodeRadius,
    _ => throw UnimplementedError(),
  };

  String get dateLabel => switch (type) {
    NoteType.yearlyFocus || NoteType.yearlySummary => date.format(pattern: 'y'),
    NoteType.monthlyFocus || NoteType.monthlySummary => date.MMM,
    NoteType.weeklyFocus || NoteType.weeklySummary => 'W${date.weekOfYear}',
    NoteType.dailyFocus || NoteType.dailySummary => date.format(pattern: 'd'),
    _ => date.format(pattern: 'yyyy-MM-dd'),
  };

  @override
  List<Object?> get props => [
    date,
    type,
    note,
    children,
    expandedAngle,
    angle,
    isSelected,
    expandedOffset,
    selectedOffset,
    unselectedOffset,
    normalOffset,
  ];

  NoteMindMapEntity copyWith({
    Jiffy? date,
    NoteType? type,
    Note? note,
    List<NoteMindMapEntity>? children,
    bool? isSelected,
    double? expandedAngle,
    double? angle,
    Offset? expandedOffset,
    Offset? normalOffset,
    Offset? selectedOffset,
    Offset? unselectedOffset,
  }) {
    return NoteMindMapEntity(
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      children: children ?? this.children,
      isSelected: isSelected ?? this.isSelected,
      expandedAngle: expandedAngle ?? this.expandedAngle,
      angle: angle ?? this.angle,
      expandedOffset: expandedOffset ?? this.expandedOffset,
      normalOffset: normalOffset ?? this.normalOffset,
      selectedOffset: selectedOffset ?? this.selectedOffset,
      unselectedOffset: unselectedOffset ?? this.unselectedOffset,
    );
  }
}
