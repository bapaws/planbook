import 'dart:math' as math;
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/discover/focus/model/note_mind_map_entity.dart';
import 'package:flutter_planbook/discover/focus/model/note_x.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/note/notes_repository.dart';

part 'discover_focus_event.dart';
part 'discover_focus_state.dart';

class DiscoverFocusBloc extends Bloc<DiscoverFocusEvent, DiscoverFocusState> {
  DiscoverFocusBloc({
    required NotesRepository notesRepository,
  }) : _notesRepository = notesRepository,
       super(DiscoverFocusState(date: Jiffy.now())) {
    on<DiscoverFocusRequested>(_onRequested);
    on<DiscoverFocusNodeSelected>(_onNodeSelected);
    on<DiscoverFocusAllNodesExpanded>(_onAllNodesExpanded);
  }

  final NotesRepository _notesRepository;

  Future<void> _onRequested(
    DiscoverFocusRequested event,
    Emitter<DiscoverFocusState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));

    final year = event.date.year;
    final note = await _notesRepository
        .getNoteByFocusAt(
          Jiffy.parseFromList([year]),
          type: NoteType.yearlyFocus,
        )
        .first;
    var mindMap = NoteMindMapEntity(
      date: Jiffy.parseFromList([year]),
      type: note?.type ?? NoteType.yearlyFocus,
      note: note,
    );
    mindMap = mindMap.copyWith(
      children: await _buildMonthlyMindMap(year, mindMap),
    );
    emit(state.copyWith(mindMap: mindMap, status: PageStatus.success));
  }

  Future<List<NoteMindMapEntity>> _buildMonthlyMindMap(
    int year,
    NoteMindMapEntity yearlyNode, {
    NoteMindMapEntity? selectedNode,
  }) async {
    final startAt = Jiffy.parseFromList([year]);
    final mindMaps = <NoteMindMapEntity>[];

    // 从1点钟方向开始（-π/2 + π/6）
    const startAngle = -math.pi / 2 + math.pi / 6;
    const anglePerMonth = 2 * math.pi / 12;
    for (var i = 0; i < 12; i++) {
      final date = startAt.add(months: i);
      final note = await _notesRepository
          .getNoteByFocusAt(date, type: NoteType.monthlyFocus)
          .first;
      final key =
          note?.key ??
          '${date.format(pattern: 'yyyy-MM-dd')}-${NoteType.monthlyFocus.name}';
      final isSelected = selectedNode != null && selectedNode.key == key;

      final angle = startAngle + i * anglePerMonth;

      var entity = NoteMindMapEntity(
        date: note?.focusAt ?? date,
        type: note?.type ?? NoteType.monthlyFocus,
        note: note,
        expandedOffset: Offset(
          (i.isEven ? 1 : 1.75) *
              kMonthlyMindMapExpandedRadius *
              math.cos(angle),
          (i.isEven ? 1 : 1.75) *
              kMonthlyMindMapExpandedRadius *
              math.sin(angle),
        ),
        selectedOffset: Offset(
          (kMonthlyMindMapRadius + kMonthlyNodeRadius / 2) * math.cos(angle),
          (kMonthlyMindMapRadius + kMonthlyNodeRadius / 2) * math.sin(angle),
        ),
        unselectedOffset: Offset(
          kMonthlyMindMapRadius * math.cos(angle),
          kMonthlyMindMapRadius * math.sin(angle),
        ),
        normalOffset: yearlyNode.normalOffset,
        expandedAngle: angle,
        angle: angle,
        isSelected: isSelected,
      );
      // if (isSelected || state.isExpandedAllNodes) {
      entity = entity.copyWith(
        children: await _buildWeeklyMindMap(year, i + 1, entity),
      );
      // }

      mindMaps.add(entity);
    }
    return mindMaps;
  }

  Future<List<NoteMindMapEntity>> _buildWeeklyMindMap(
    int year,
    int month,
    NoteMindMapEntity monthlyNode, {
    NoteMindMapEntity? selectedNode,
  }) async {
    final startOfMonth = Jiffy.parseFromList([year, month]);
    final endOfMonth = startOfMonth.endOf(Unit.month);
    final mindMaps = <NoteMindMapEntity>[];

    final weekCount = endOfMonth.weekOfYear - startOfMonth.weekOfYear + 1;

    // 计算周节点分布：以月节点角度为中轴，向两侧扩展
    final expandedAnglePerWeek = 2 * math.pi / weekCount; // 每周约占的角度
    // 总角度范围
    final expandedTotalSweep = (weekCount - 1) * expandedAnglePerWeek;
    // 起始偏移（让中轴对齐月节点）
    final expandedWeekStartAngle =
        monthlyNode.expandedAngle - expandedTotalSweep / 2;

    const anglePerWeek = 2 * math.pi / 24; // 每周约占的角度
    final weekStartAngle =
        monthlyNode.angle - (weekCount - 1) * anglePerWeek / 2;

    for (var i = 0; i < weekCount; i++) {
      final startOfWeek = i == 0
          ? startOfMonth
          : startOfMonth.startOf(Unit.week).add(weeks: i);
      final note = await _notesRepository
          .getNoteByFocusAt(
            startOfWeek.startOf(Unit.week),
            type: NoteType.weeklyFocus,
          )
          .first;
      final key =
          note?.key ??
          '${startOfWeek.format(pattern: 'yyyy-MM-dd')}'
              '-${NoteType.weeklyFocus.name}';
      final isSelected = selectedNode != null && selectedNode.key == key;

      final expandedAngle = expandedWeekStartAngle + i * expandedAnglePerWeek;
      final expandedDx = kWeeklyMindMapExpandedRadius * math.cos(expandedAngle);
      final expandedDy = kWeeklyMindMapExpandedRadius * math.sin(expandedAngle);

      final angle = weekStartAngle + i * anglePerWeek;

      var entity = NoteMindMapEntity(
        date: startOfWeek,
        type: NoteType.weeklyFocus,
        note: note,
        expandedOffset: Offset(
          monthlyNode.expandedOffset.dx + expandedDx,
          monthlyNode.expandedOffset.dy + expandedDy,
        ),
        selectedOffset: Offset(
          (kWeeklyMindMapRadius + kWeeklyNodeRadius) * math.cos(angle),
          (kWeeklyMindMapRadius + kWeeklyNodeRadius) * math.sin(angle),
        ),
        unselectedOffset: Offset(
          kWeeklyMindMapRadius * math.cos(angle),
          kWeeklyMindMapRadius * math.sin(angle),
        ),
        normalOffset: monthlyNode.normalOffset,
        expandedAngle: expandedAngle,
        angle: angle,
        isSelected: isSelected,
      );
      // if (isSelected || state.isExpandedAllNodes) {
      entity = entity.copyWith(
        children: await __buildDailyMindMap(startOfWeek, entity, monthlyNode),
      );
      // }
      mindMaps.add(entity);
    }
    return mindMaps;
  }

  Future<List<NoteMindMapEntity>> __buildDailyMindMap(
    Jiffy startOfWeek,
    NoteMindMapEntity weeklyNode,
    NoteMindMapEntity monthlyNode,
  ) async {
    final mindMaps = <NoteMindMapEntity>[];

    // 7天以周角度为中轴对称分布
    final endOfWeek = startOfWeek.endOf(Unit.week).month == startOfWeek.month
        ? startOfWeek.endOf(Unit.week)
        : startOfWeek.endOf(Unit.month);
    final dayCount = endOfWeek.diff(startOfWeek, unit: Unit.day).toInt() + 1;
    const expandedAnglePerDay = 2 * math.pi / 8; // 每周约占的角度
    final expandedDayStartAngle =
        weeklyNode.expandedAngle - 8 * expandedAnglePerDay / 2;

    const anglePerDay = 2 * math.pi / 36; // 每周约占的角度
    final dayStartAngle = weeklyNode.angle - (dayCount - 1) * anglePerDay / 2;

    for (var i = 0; i < dayCount; i++) {
      final date = startOfWeek.add(days: i);
      if (date.month != startOfWeek.month) {
        continue;
      }
      final note = await _notesRepository.getNoteByFocusAt(date).first;

      final expandedAngle =
          expandedDayStartAngle + (date.dayOfWeek) * expandedAnglePerDay;
      final expandedDx = kDailyMindMapExpandedRadius * math.cos(expandedAngle);
      final expandedDy = kDailyMindMapExpandedRadius * math.sin(expandedAngle);

      final angle = dayStartAngle + i * anglePerDay;

      mindMaps.add(
        NoteMindMapEntity(
          date: date,
          note: note,
          type: note?.type ?? NoteType.dailyFocus,
          expandedOffset: Offset(
            weeklyNode.expandedOffset.dx + expandedDx,
            weeklyNode.expandedOffset.dy + expandedDy,
          ),
          selectedOffset: Offset(
            (kDailyMindMapRadius + kDailyNodeRadius) * math.cos(angle),
            (kDailyMindMapRadius + kDailyNodeRadius) * math.sin(angle),
          ),
          unselectedOffset: Offset(
            kDailyMindMapRadius * math.cos(angle),
            kDailyMindMapRadius * math.sin(angle),
          ),
          normalOffset: Offset(
            weeklyNode.normalOffset.dx,
            weeklyNode.normalOffset.dy,
          ),
          expandedAngle: angle,
          angle: angle,
        ),
      );
    }
    return mindMaps;
  }

  // Future<List<NoteMindMapEntity>> _buildDailyMindMap(
  //   Jiffy startOfWeek,
  //   NoteMindMapEntity monthlyNode,
  // ) async {
  //   final mindMaps = <NoteMindMapEntity>[];

  //   // 7天以周角度为中轴对称分布
  //   final dayCount = monthlyNode.date.daysInMonth;
  //   final anglePerDay = 2 * math.pi / (dayCount + 1); // 每周约占的角度
  //   final totalSweep = (dayCount - 1) * anglePerDay;
  //   final dayStartAngle = monthlyNode.angle - totalSweep / 2;

  //   final startOfMonth = monthlyNode.date.startOf(Unit.month);
  //   final startAt = startOfWeek;
  //   final endOfMonth = startOfMonth.endOf(Unit.month);
  //   final endOfWeek = startOfWeek.endOf(Unit.week);
  //   final endAt = endOfWeek.isAfter(endOfMonth) ? endOfMonth : endOfWeek;
  //   final count = endAt.diff(startAt, unit: Unit.day).toInt() + 1;
  //   for (var i = 0; i < count; i++) {
  //     final date = startAt.add(days: i);
  //     final note = await _notesRepository.getNoteByFocusAt(date).first;

  //     final angle = dayStartAngle + (date.date - 1) * anglePerDay;
  //     final dx = kDailyMindMapRadius * math.cos(angle);
  //     final dy = kDailyMindMapRadius * math.sin(angle);

  //     mindMaps.add(
  //       NoteMindMapEntity(
  //         date: date,
  //         note: note,
  //         type: note?.type ?? NoteType.dailyFocus,
  //         expandedOffset: Offset(
  //           monthlyNode.expandedOffset.dx + dx,
  //           monthlyNode.expandedOffset.dy + dy,
  //         ),
  //         selectedOffset: Offset(
  //           monthlyNode.selectedOffset.dx + dx,
  //           monthlyNode.selectedOffset.dy + dy,
  //         ),
  //         unselectedOffset: Offset(
  //           monthlyNode.unselectedOffset.dx,
  //           monthlyNode.unselectedOffset.dy,
  //         ),
  //         size: kDailyNodeRadius,
  //         angle: angle,
  //       ),
  //     );
  //   }
  //   return mindMaps;
  // }

  Future<void> _onNodeSelected(
    DiscoverFocusNodeSelected event,
    Emitter<DiscoverFocusState> emit,
  ) async {
    final yearlyNode = state.mindMap;
    if (yearlyNode == null) return;

    final selectedYearlyNode = event.node.type.isYearly
        ? event.node
        : state.selectedYearlyNode;
    final selectedMonthlyNode = event.node.type.isMonthly
        ? event.node
        : state.selectedMonthlyNode;
    final selectedWeeklyNode = event.node.type.isWeekly
        ? event.node
        : state.selectedWeeklyNode;
    final selectedDailyNode = event.node.type.isDaily
        ? event.node
        : state.selectedDailyNode;

    final isYearlySelected = yearlyNode.key == event.node.key
        ? !yearlyNode.isSelected
        : yearlyNode.isSelected;
    final monthlyNodes = [...yearlyNode.children];
    for (var i = 0; i < monthlyNodes.length; i++) {
      final monthlyNode = monthlyNodes[i];
      final isMonthlySelected = monthlyNode.key == event.node.key
          ? !monthlyNode.isSelected
          : isYearlySelected &&
                !event.node.type.isMonthly &&
                monthlyNode.isSelected;
      final weeklyNodes = [...monthlyNode.children];
      for (var j = 0; j < weeklyNodes.length; j++) {
        final weeklyNode = weeklyNodes[j];
        final isWeeklySelected = weeklyNode.key == event.node.key
            ? !weeklyNode.isSelected
            : isMonthlySelected &&
                  !event.node.type.isWeekly &&
                  weeklyNode.isSelected;
        final dailyNodes = [...weeklyNode.children];
        for (var k = 0; k < dailyNodes.length; k++) {
          final dailyNode = dailyNodes[k];
          final isDailySelected = dailyNode.key == event.node.key
              ? !dailyNode.isSelected
              : isWeeklySelected &&
                    !event.node.type.isDaily &&
                    dailyNode.isSelected;
          dailyNodes[k] = dailyNode.copyWith(
            isSelected: isDailySelected,
            normalOffset: isDailySelected
                ? dailyNode.selectedOffset
                : isWeeklySelected
                ? dailyNode.unselectedOffset
                : isMonthlySelected
                ? weeklyNode.unselectedOffset
                : isYearlySelected
                ? (monthlyNode.unselectedOffset)
                : yearlyNode.unselectedOffset,
          );
        }
        weeklyNodes[j] = weeklyNode.copyWith(
          children: dailyNodes,
          isSelected: isWeeklySelected,
          normalOffset: isWeeklySelected
              ? weeklyNode.selectedOffset
              : isMonthlySelected
              ? weeklyNode.unselectedOffset
              : isYearlySelected
              ? monthlyNode.unselectedOffset
              : yearlyNode.unselectedOffset,
        );
      }
      monthlyNodes[i] = monthlyNodes[i].copyWith(
        children: weeklyNodes,
        isSelected: isMonthlySelected,
        normalOffset: isMonthlySelected
            ? monthlyNode.selectedOffset
            : isYearlySelected
            ? monthlyNode.unselectedOffset
            : yearlyNode.unselectedOffset,
      );
    }
    emit(
      state.copyWith(
        selectedYearlyNode: selectedYearlyNode,
        selectedMonthlyNode: selectedMonthlyNode,
        selectedWeeklyNode: selectedWeeklyNode,
        selectedDailyNode: selectedDailyNode,
        mindMap: yearlyNode.copyWith(
          children: monthlyNodes,
          isSelected: isYearlySelected,
        ),
      ),
    );
  }

  Future<void> _onAllNodesExpanded(
    DiscoverFocusAllNodesExpanded event,
    Emitter<DiscoverFocusState> emit,
  ) async {
    emit(
      state.copyWith(
        isExpandedAllNodes: !state.isExpandedAllNodes,
      ),
    );

    // add(DiscoverFocusNodeSelected(node: state.selectedYearlyNode!));
  }
}
