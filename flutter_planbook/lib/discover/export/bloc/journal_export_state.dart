part of 'journal_export_bloc.dart';

sealed class JournalExportState extends Equatable {
  const JournalExportState();

  @override
  List<Object?> get props => [];
}

/// 已选导出日期区间（均为当天 0 点起的日历日）
final class JournalExportReady extends JournalExportState {
  const JournalExportReady({
    required this.startDate,
    required this.endDate,
  });

  final Jiffy startDate;
  final Jiffy endDate;

  @override
  List<Object?> get props => [startDate, endDate];

  JournalExportReady copyWith({
    Jiffy? startDate,
    Jiffy? endDate,
  }) {
    return JournalExportReady(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
