import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_layout_item.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_metrics.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_core/data/page_status.dart';

part 'task_time_block_event.dart';
part 'task_time_block_state.dart';

/// 时间块视图 BLoC：预计算布局与交互状态，不依赖其他 BLoC
///
/// 任务数据由页面通过 BlocListener 转发为 [TaskTimeBlockTasksUpdated]。
class TaskTimeBlockBloc extends Bloc<TaskTimeBlockEvent, TaskTimeBlockState> {
  TaskTimeBlockBloc({
    required Jiffy date,
  }) : super(TaskTimeBlockState.initial(date: date)) {
    on<TaskTimeBlockStarted>(_onStarted, transformer: restartable());
    on<TaskTimeBlockTasksUpdated>(_onTasksUpdated, transformer: restartable());
    on<TaskTimeBlockHoverUpdated>(_onHoverUpdated);
    on<TaskTimeBlockHoverCleared>(_onHoverCleared);
  }

  Future<void> _onStarted(
    TaskTimeBlockStarted event,
    Emitter<TaskTimeBlockState> emit,
  ) async {
    emit(_mapClockToState());

    await emit.forEach(
      _minuteClockStream(),
      onData: (_) => _mapClockToState(),
    );
  }

  void _onTasksUpdated(
    TaskTimeBlockTasksUpdated event,
    Emitter<TaskTimeBlockState> emit,
  ) {
    emit(
      state.copyWith(
        status: PageStatus.success,
        items: buildTaskTimeBlockLayoutItems(
          tasks: event.tasks,
          dayStart: state.dayStart,
          dayEnd: state.dayEnd,
        ),
      ),
    );
  }

  void _onHoverUpdated(
    TaskTimeBlockHoverUpdated event,
    Emitter<TaskTimeBlockState> emit,
  ) {
    if (state.hoverMinutes == event.minutes) return;
    emit(
      state.copyWith(
        hoverMinutes: () => event.minutes,
        hoverLabel: () => TaskTimeBlockMetrics.formatMinutes(event.minutes),
      ),
    );
  }

  void _onHoverCleared(
    TaskTimeBlockHoverCleared event,
    Emitter<TaskTimeBlockState> emit,
  ) {
    if (state.hoverMinutes == null) return;
    emit(
      state.copyWith(
        hoverMinutes: () => null,
        hoverLabel: () => null,
      ),
    );
  }

  TaskTimeBlockState _mapClockToState() {
    final now = Jiffy.now();
    if (!now.isSame(state.dayStart, unit: Unit.day)) {
      return state.copyWith(
        currentTimeMinutes: () => null,
        currentTimeLabel: () => null,
        currentTimeTop: () => null,
      );
    }

    final minutes = now.diff(state.dayStart, unit: Unit.minute).toInt();
    return state.copyWith(
      currentTimeMinutes: () => minutes,
      currentTimeLabel: () => TaskTimeBlockMetrics.formatMinutes(
        now.hour * 60 + now.minute,
      ),
      currentTimeTop: () => TaskTimeBlockMetrics.topFromMinutes(minutes),
    );
  }

  /// 对齐到下一分钟整点后持续产出，供 emit.forEach 订阅
  Stream<void> _minuteClockStream() async* {
    while (true) {
      final now = DateTime.now();
      final delay = Duration(
        milliseconds: 60000 - (now.second * 1000 + now.millisecond),
      );
      await Future<void>.delayed(delay);
      yield null;
    }
  }
}
