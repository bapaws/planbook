import 'dart:collection';

import 'package:flutter_planbook/discover/daily/bloc/journal_daily_bloc.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// Per-year cache of daily journal blocs, keyed internally by day-of-year
/// derived from [Jiffy] (start of day vs start of year).
///
/// Exposed with `RepositoryProvider` from the journal tab; half pages use
/// `context.read<JournalDailyBlocManager>()`.
///
/// Uses LRU (see max cap below) plus radius-based eviction after prefetch
/// so memory stays bounded while flipping through the year.
class JournalDailyBlocManager {
  JournalDailyBlocManager({
    required NotesRepository notesRepository,
    required TasksRepository tasksRepository,
  }) : _notesRepository = notesRepository,
       _tasksRepository = tasksRepository;

  /// Hard cap; oldest touched entries are closed first (LRU).
  static const int _maxCachedBlocs = 24;

  /// After prefetch, drop days farther than this from the journal center day.
  static const int _retentionRadius = 14;

  final NotesRepository _notesRepository;
  final TasksRepository _tasksRepository;

  final LinkedHashMap<int, JournalDailyBloc> _blocs = LinkedHashMap();

  static int _indexInYear(Jiffy date) {
    final startOfYear = date.startOf(Unit.year);
    return date.startOf(Unit.day).diff(startOfYear, unit: Unit.day).toInt();
  }

  /// Shared bloc for the calendar day of [date]; creates and starts load on
  /// first use.
  JournalDailyBloc blocForDay({required Jiffy date}) {
    final key = _indexInYear(date);
    final startOfYear = date.startOf(Unit.year);
    final calendarDate = startOfYear.add(days: key);

    final existing = _blocs.remove(key);
    if (existing != null) {
      _blocs[key] = existing;
      return existing;
    }

    final bloc = JournalDailyBloc(
      date: calendarDate,
      notesRepository: _notesRepository,
      tasksRepository: _tasksRepository,
    )..add(const JournalDailyRequested());
    _blocs[key] = bloc;
    _evictLruWhileAbove(_maxCachedBlocs);
    return bloc;
  }

  /// Eagerly warms blocs near [centerDate] (default ± calendar days), then
  /// evicts entries outside retention radius of that center day.
  void prefetchDaysAround({
    required Jiffy centerDate,
    required int dayCount,
    int radius = 2,
  }) {
    final startOfYear = centerDate.startOf(Unit.year);
    final center = _indexInYear(centerDate);
    for (var delta = -radius; delta <= radius; delta++) {
      final i = center + delta;
      if (i < 0 || i >= dayCount) continue;
      blocForDay(date: startOfYear.add(days: i));
    }
    _trimOutsideRadius(
      center,
      dayCount: dayCount,
      radius: _retentionRadius,
    );
    _evictLruWhileAbove(_maxCachedBlocs);
  }

  void _trimOutsideRadius(
    int center, {
    required int dayCount,
    required int radius,
  }) {
    final toRemove = <int>[];
    for (final k in _blocs.keys) {
      if (k < 0 || k >= dayCount) {
        toRemove.add(k);
        continue;
      }
      if ((k - center).abs() > radius) {
        toRemove.add(k);
      }
    }
    for (final k in toRemove) {
      _blocs.remove(k)?.close();
    }
  }

  void _evictLruWhileAbove(int max) {
    while (_blocs.length > max) {
      final k = _blocs.keys.first;
      _blocs.remove(k)?.close();
    }
  }

  void dispose() {
    for (final bloc in _blocs.values) {
      bloc.close();
    }
    _blocs.clear();
  }
}
