import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';

final class TaskDurationEntity extends Equatable {
  const TaskDurationEntity({
    required this.isAllDay,
    this.startAt,
    this.endAt,
  });

  final Jiffy? startAt;
  final Jiffy? endAt;
  final bool isAllDay;

  @override
  List<Object?> get props => [startAt, endAt, isAllDay];

  TaskDurationEntity copyWith({
    Jiffy? startAt,
    Jiffy? endAt,
    bool? isAllDay,
  }) {
    return TaskDurationEntity(
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }
}
