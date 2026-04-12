part of 'journal_export_bloc.dart';

sealed class JournalExportEvent extends Equatable {
  const JournalExportEvent();

  @override
  List<Object?> get props => [];
}

/// 用户修改开始日期
final class JournalExportStartDateChanged extends JournalExportEvent {
  const JournalExportStartDateChanged(this.date);

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

/// 用户修改结束日期
final class JournalExportEndDateChanged extends JournalExportEvent {
  const JournalExportEndDateChanged(this.date);

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

/// 快捷范围：今天 / 本周 / 本月 / 今年
enum JournalExportPreset {
  today,
  thisWeek,
  thisMonth,
  thisYear,
}

final class JournalExportPresetSelected extends JournalExportEvent {
  const JournalExportPresetSelected(this.preset);

  final JournalExportPreset preset;

  @override
  List<Object?> get props => [preset];
}
