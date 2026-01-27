import 'dart:math' as math;
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/discover/focus/model/note_mind_map_entity.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/note/notes_repository.dart';

part 'discover_focus_event.dart';
part 'discover_focus_state.dart';

class DiscoverFocusBloc extends Bloc<DiscoverFocusEvent, DiscoverFocusState> {
  DiscoverFocusBloc({
    required NotesRepository notesRepository,
    this.isSummary = false,
  }) : _notesRepository = notesRepository,
       super(DiscoverFocusState(date: Jiffy.now())) {
    on<DiscoverFocusRequested>(_onRequested);
    on<DiscoverFocusNodeSelected>(_onNodeSelected, transformer: sequential());
    on<DiscoverFocusAllNodesExpanded>(_onAllNodesExpanded);
    on<DiscoverFocusCalendarExpanded>(_onCalendarExpanded);
    on<DiscoverFocusCalendarDateSelected>(_onCalendarDateSelected);
  }

  final Map<NoteType, Jiffy> selectedNodeDates = {};
  final NotesRepository _notesRepository;

  final bool isSummary;
  NoteType get yearlyNoteType =>
      isSummary ? NoteType.yearlySummary : NoteType.yearlyFocus;
  NoteType get monthlyNoteType =>
      isSummary ? NoteType.monthlySummary : NoteType.monthlyFocus;
  NoteType get weeklyNoteType =>
      isSummary ? NoteType.weeklySummary : NoteType.weeklyFocus;
  NoteType get dailyNoteType =>
      isSummary ? NoteType.dailySummary : NoteType.dailyFocus;

  Future<void> _onRequested(
    DiscoverFocusRequested event,
    Emitter<DiscoverFocusState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));

    // if (event.date != null && event.noteType != null) {
    //   for (final type in NoteType.values) {
    //     if (type.index < event.noteType!.index) continue;
    //     selectedNodeDates[type] = event.date!.startOf(type.unit);
    //   }
    // }

    final year = (event.date ?? Jiffy.now()).year;
    final note = await _notesRepository
        .getNoteByFocusAt(
          Jiffy.parseFromList([year]),
          type: yearlyNoteType,
        )
        .first;
    var mindMap = NoteMindMapEntity(
      date: Jiffy.parseFromList([year]),
      type: note?.type ?? yearlyNoteType,
      note: note,
      isSelected: selectedNodeDates[note?.type]?.year == year,
    );
    mindMap = mindMap.copyWith(
      children: await _buildMonthlyMindMap(year, mindMap),
    );
    emit(state.copyWith(mindMap: mindMap, status: PageStatus.success));
  }

  Future<List<NoteMindMapEntity>> _buildMonthlyMindMap(
    int year,
    NoteMindMapEntity yearlyNode,
  ) async {
    final startAt = Jiffy.parseFromList([year]);
    final mindMaps = <NoteMindMapEntity>[];

    // 从1点钟方向开始（-π/2 + π/6）
    const startAngle = -math.pi / 2 + math.pi / 6;
    const anglePerMonth = 2 * math.pi / 12;
    for (var i = 0; i < 12; i++) {
      final date = startAt.add(months: i);
      final note = await _notesRepository
          .getNoteByFocusAt(
            date,
            type: monthlyNoteType,
          )
          .first;

      final isSelected =
          selectedNodeDates[monthlyNoteType]?.isSame(
            date,
            unit: Unit.month,
          ) ??
          false;

      final angle = startAngle + i * anglePerMonth;

      final selectedOffset = Offset(
        (kMonthlyMindMapRadius + kMonthlyNodeRadius / 2) * math.cos(angle),
        (kMonthlyMindMapRadius + kMonthlyNodeRadius / 2) * math.sin(angle),
      );
      final unselectedOffset = Offset(
        kMonthlyMindMapRadius * math.cos(angle),
        kMonthlyMindMapRadius * math.sin(angle),
      );
      var entity = NoteMindMapEntity(
        date: note?.focusAt ?? date,
        type: note?.type ?? monthlyNoteType,
        note: note,
        expandedOffset: Offset(
          (i.isEven ? 1 : 1.75) *
              kMonthlyMindMapExpandedRadius *
              math.cos(angle),
          (i.isEven ? 1 : 1.75) *
              kMonthlyMindMapExpandedRadius *
              math.sin(angle),
        ),
        selectedOffset: selectedOffset,
        unselectedOffset: unselectedOffset,
        normalOffset: isSelected
            ? selectedOffset
            : yearlyNode.isSelected
            ? unselectedOffset
            : yearlyNode.normalOffset,
        expandedAngle: angle,
        angle: angle,
        isSelected: isSelected,
        isVisible: yearlyNode.isSelected,
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
    NoteMindMapEntity monthlyNode,
  ) async {
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
            type: weeklyNoteType,
          )
          .first;
      final isSelected =
          selectedNodeDates[weeklyNoteType]?.isSame(
            startOfWeek,
            unit: Unit.week,
          ) ??
          false;

      final expandedAngle = expandedWeekStartAngle + i * expandedAnglePerWeek;
      final expandedDx = kWeeklyMindMapExpandedRadius * math.cos(expandedAngle);
      final expandedDy = kWeeklyMindMapExpandedRadius * math.sin(expandedAngle);

      final angle = weekStartAngle + i * anglePerWeek;

      final unselectedOffset = Offset(
        kWeeklyMindMapRadius * math.cos(angle),
        kWeeklyMindMapRadius * math.sin(angle),
      );

      // 计算从月选中位置到周未选中位置的角度
      final offset = unselectedOffset - monthlyNode.selectedOffset;
      final angleFromMonthlySelected = math.atan2(offset.dy, offset.dx);
      final distance = math.sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
      final selectedOffset = Offset(
        monthlyNode.selectedOffset.dx +
            (distance + kWeeklyNodeRadius / 2) *
                math.cos(angleFromMonthlySelected),
        monthlyNode.selectedOffset.dy +
            (distance + kWeeklyNodeRadius / 2) *
                math.sin(angleFromMonthlySelected),
      );
      var entity = NoteMindMapEntity(
        date: startOfWeek,
        type: note?.type ?? weeklyNoteType,
        note: note,
        expandedOffset: Offset(
          monthlyNode.expandedOffset.dx + expandedDx,
          monthlyNode.expandedOffset.dy + expandedDy,
        ),
        selectedOffset: selectedOffset,
        unselectedOffset: unselectedOffset,
        normalOffset: isSelected
            ? selectedOffset
            : monthlyNode.isSelected
            ? unselectedOffset
            : monthlyNode.normalOffset,
        expandedAngle: expandedAngle,
        angle: angle,
        isSelected: isSelected,
        isVisible: monthlyNode.isSelected,
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
      final note = await _notesRepository
          .getNoteByFocusAt(
            date,
            type: dailyNoteType,
          )
          .first;

      final expandedAngle =
          expandedDayStartAngle + (date.dayOfWeek) * expandedAnglePerDay;
      final expandedDx = kDailyMindMapExpandedRadius * math.cos(expandedAngle);
      final expandedDy = kDailyMindMapExpandedRadius * math.sin(expandedAngle);

      final angle = dayStartAngle + i * anglePerDay;

      final isSelected =
          selectedNodeDates[dailyNoteType]?.isSame(
            date,
            unit: Unit.day,
          ) ??
          false;
      final unselectedOffset = Offset(
        kDailyMindMapRadius * math.cos(angle),
        kDailyMindMapRadius * math.sin(angle),
      );
      final offset = unselectedOffset - weeklyNode.selectedOffset;
      final angleFromWeeklySelected = math.atan2(offset.dy, offset.dx);
      final distance = math.sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
      final selectedOffset = Offset(
        weeklyNode.selectedOffset.dx +
            (distance + kDailyNodeRadius / 2) *
                math.cos(angleFromWeeklySelected),
        weeklyNode.selectedOffset.dy +
            (distance + kDailyNodeRadius / 2) *
                math.sin(angleFromWeeklySelected),
      );
      mindMaps.add(
        NoteMindMapEntity(
          date: date,
          note: note,
          type: note?.type ?? dailyNoteType,
          expandedOffset: Offset(
            weeklyNode.expandedOffset.dx + expandedDx,
            weeklyNode.expandedOffset.dy + expandedDy,
          ),
          selectedOffset: selectedOffset,
          unselectedOffset: unselectedOffset,
          normalOffset: isSelected
              ? selectedOffset
              : weeklyNode.isSelected
              ? unselectedOffset
              : weeklyNode.normalOffset,
          expandedAngle: angle,
          angle: angle,
          isSelected:
              selectedNodeDates[dailyNoteType]?.isSame(
                date,
                unit: Unit.day,
              ) ??
              false,
          isVisible: weeklyNode.isSelected,
        ),
      );
    }
    return mindMaps;
  }

  Future<void> _onNodeSelected(
    DiscoverFocusNodeSelected event,
    Emitter<DiscoverFocusState> emit,
  ) async {
    final yearlyNode = state.mindMap;
    if (yearlyNode == null) return;

    final newYearlyNode = switch (event.node.type) {
      NoteType.yearlyFocus || NoteType.yearlySummary => _handleSelectYearlyNode(
        yearlyNode,
        event.node,
      ),
      NoteType.monthlyFocus ||
      NoteType.monthlySummary => _handleSelectMonthlyNode(
        yearlyNode,
        event.node,
      ),
      NoteType.weeklyFocus || NoteType.weeklySummary => _handleSelectWeeklyNode(
        yearlyNode,
        event.node,
      ),
      NoteType.dailyFocus || NoteType.dailySummary => _handleSelectDailyNode(
        yearlyNode,
        event.node,
      ),
      _ => yearlyNode,
    };
    emit(state.copyWith(mindMap: newYearlyNode));
  }

  NoteMindMapEntity _handleSelectYearlyNode(
    NoteMindMapEntity yearlyNode,
    NoteMindMapEntity selectedNode,
  ) {
    final isYearlySelected =
        yearlyNode.key == selectedNode.key && !yearlyNode.isSelected;
    final monthlyNodes = [...yearlyNode.children];
    for (var i = 0; i < monthlyNodes.length; i++) {
      final monthlyNode = monthlyNodes[i];
      final monthlyNormalOffset = isYearlySelected
          ? monthlyNode.unselectedOffset
          : yearlyNode.unselectedOffset;
      final weeklyNodes = [...monthlyNode.children];
      for (var j = 0; j < weeklyNodes.length; j++) {
        final weeklyNode = weeklyNodes[j];
        final dailyNodes = [...weeklyNode.children];
        for (var k = 0; k < dailyNodes.length; k++) {
          final dailyNode = dailyNodes[k];
          dailyNodes[k] = dailyNode.copyWith(
            isSelected: false,
            normalOffset: monthlyNormalOffset,
            isVisible: false,
          );
        }
        weeklyNodes[j] = weeklyNode.copyWith(
          children: dailyNodes,
          isSelected: false,
          normalOffset: monthlyNormalOffset,
          isVisible: false,
        );
      }
      monthlyNodes[i] = monthlyNode.copyWith(
        children: weeklyNodes,
        isSelected: false,
        normalOffset: monthlyNormalOffset,
        isVisible: isYearlySelected,
      );
    }
    return yearlyNode.copyWith(
      children: monthlyNodes,
      isSelected: isYearlySelected,
    );
  }

  NoteMindMapEntity _handleSelectMonthlyNode(
    NoteMindMapEntity yearlyNode,
    NoteMindMapEntity selectedNode,
  ) {
    final monthlyNodes = [...yearlyNode.children];
    for (var i = 0; i < monthlyNodes.length; i++) {
      final monthlyNode = monthlyNodes[i];
      final isMonthlySelected =
          monthlyNode.key == selectedNode.key && !monthlyNode.isSelected;
      final monthlyNormalOffset = isMonthlySelected
          ? monthlyNode.selectedOffset
          : monthlyNode.unselectedOffset;
      final weeklyNodes = [...monthlyNode.children];
      for (var j = 0; j < weeklyNodes.length; j++) {
        final weeklyNode = weeklyNodes[j];
        final weeklyNormalOffset = isMonthlySelected
            ? weeklyNode.unselectedOffset
            : monthlyNode.unselectedOffset;
        final dailyNodes = [...weeklyNode.children];
        for (var k = 0; k < dailyNodes.length; k++) {
          final dailyNode = dailyNodes[k];
          dailyNodes[k] = dailyNode.copyWith(
            isSelected: false,
            isVisible: false,
            normalOffset: weeklyNormalOffset,
          );
        }
        weeklyNodes[j] = weeklyNode.copyWith(
          children: dailyNodes,
          isSelected: false,
          normalOffset: weeklyNormalOffset,
          isVisible: isMonthlySelected,
        );
      }
      monthlyNodes[i] = monthlyNode.copyWith(
        children: weeklyNodes,
        isSelected: isMonthlySelected,
        normalOffset: monthlyNormalOffset,
        isVisible: yearlyNode.isSelected,
      );
    }
    return yearlyNode.copyWith(
      children: monthlyNodes,
    );
  }

  NoteMindMapEntity _handleSelectWeeklyNode(
    NoteMindMapEntity yearlyNode,
    NoteMindMapEntity selectedNode,
  ) {
    final monthlyNodes = [...yearlyNode.children];
    for (var i = 0; i < monthlyNodes.length; i++) {
      final monthlyNode = monthlyNodes[i];

      final weeklyNodes = [...monthlyNode.children];
      for (var j = 0; j < weeklyNodes.length; j++) {
        final weeklyNode = weeklyNodes[j];
        final isWeeklySelected =
            weeklyNode.key == selectedNode.key && !weeklyNode.isSelected;
        final weeklyNormalOffset = isWeeklySelected
            ? weeklyNode.selectedOffset
            : monthlyNode.isSelected
            ? weeklyNode.unselectedOffset
            : monthlyNode.unselectedOffset;
        final dailyNodes = [...weeklyNode.children];
        for (var k = 0; k < dailyNodes.length; k++) {
          final dailyNode = dailyNodes[k];
          final dailyNormalOffset = isWeeklySelected
              ? dailyNode.unselectedOffset
              : weeklyNormalOffset;
          dailyNodes[k] = dailyNode.copyWith(
            isSelected: false,
            normalOffset: dailyNormalOffset,
            isVisible: isWeeklySelected,
          );
        }
        weeklyNodes[j] = weeklyNode.copyWith(
          children: dailyNodes,
          isSelected: isWeeklySelected,
          normalOffset: weeklyNormalOffset,
        );
      }
      monthlyNodes[i] = monthlyNode.copyWith(
        children: weeklyNodes,
      );
    }
    return yearlyNode.copyWith(
      children: monthlyNodes,
    );
  }

  NoteMindMapEntity _handleSelectDailyNode(
    NoteMindMapEntity yearlyNode,
    NoteMindMapEntity selectedNode,
  ) {
    final monthlyNodes = [...yearlyNode.children];
    for (var i = 0; i < monthlyNodes.length; i++) {
      final monthlyNode = monthlyNodes[i];
      final weeklyNodes = [...monthlyNode.children];
      for (var j = 0; j < weeklyNodes.length; j++) {
        final weeklyNode = weeklyNodes[j];
        final dailyNodes = [...weeklyNode.children];
        for (var k = 0; k < dailyNodes.length; k++) {
          final dailyNode = dailyNodes[k];
          final isDailySelected =
              dailyNode.key == selectedNode.key && !dailyNode.isSelected;
          final dailyNormalOffset = isDailySelected
              ? dailyNode.selectedOffset
              : weeklyNode.isSelected
              ? dailyNode.unselectedOffset
              : monthlyNode.isSelected
              ? weeklyNode.unselectedOffset
              : yearlyNode.isSelected
              ? monthlyNode.unselectedOffset
              : yearlyNode.unselectedOffset;
          dailyNodes[k] = dailyNode.copyWith(
            isSelected: isDailySelected,
            normalOffset: dailyNormalOffset,
            isVisible: weeklyNode.isSelected,
          );
        }
        weeklyNodes[j] = weeklyNode.copyWith(
          children: dailyNodes,
        );
      }
      monthlyNodes[i] = monthlyNode.copyWith(
        children: weeklyNodes,
      );
    }
    return yearlyNode.copyWith(
      children: monthlyNodes,
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

  Future<void> _onCalendarExpanded(
    DiscoverFocusCalendarExpanded event,
    Emitter<DiscoverFocusState> emit,
  ) async {
    emit(state.copyWith(isCalendarExpanded: !state.isCalendarExpanded));
  }

  Future<void> _onCalendarDateSelected(
    DiscoverFocusCalendarDateSelected event,
    Emitter<DiscoverFocusState> emit,
  ) async {
    emit(state.copyWith(date: event.date));
    add(DiscoverFocusRequested(date: event.date));
  }
}
