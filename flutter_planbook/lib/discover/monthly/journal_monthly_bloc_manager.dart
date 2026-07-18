import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/monthly/bloc/journal_monthly_bloc.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 按月缓存 [JournalMonthlyBloc]，避免翻页时重复创建和监听。
class JournalMonthlyBlocManager {
  JournalMonthlyBlocManager({
    required NotesRepository notesRepository,
    required TasksRepository tasksRepository,
  }) : _notesRepository = notesRepository,
       _tasksRepository = tasksRepository;

  final NotesRepository _notesRepository;
  final TasksRepository _tasksRepository;

  static const int _maxCachedBlocs = 12;

  final _blocs = HashMap<int, JournalMonthlyBloc>();
  final _accessOrder = <int>[];

  int _indexForMonth(Jiffy month) {
    final normalized = month.startOf(Unit.month);
    return normalized.year * 12 + normalized.month;
  }

  JournalMonthlyBloc blocForMonth({required Jiffy month}) {
    final index = _indexForMonth(month);
    var bloc = _blocs[index];
    if (bloc == null) {
      bloc = JournalMonthlyBloc(
        month: month.startOf(Unit.month),
        notesRepository: _notesRepository,
        tasksRepository: _tasksRepository,
      );
      _blocs[index] = bloc;
      _evictLruWhileAbove(_maxCachedBlocs);
    }
    _accessOrder
      ..remove(index)
      ..add(index);
    return bloc;
  }

  void prefetchMonthsAround({required Jiffy centerDate}) {
    final center = centerDate.startOf(Unit.month);
    for (var i = -1; i <= 1; i++) {
      blocForMonth(month: center.add(months: i));
    }
  }

  void _evictLruWhileAbove(int maxSize) {
    while (_blocs.length > maxSize) {
      final oldest = _accessOrder.firstOrNull;
      if (oldest == null) return;
      _accessOrder.removeAt(0);
      final bloc = _blocs.remove(oldest);
      bloc?.close();
    }
  }

  @mustCallSuper
  void dispose() {
    for (final bloc in _blocs.values) {
      bloc.close();
    }
    _blocs.clear();
    _accessOrder.clear();
  }
}
