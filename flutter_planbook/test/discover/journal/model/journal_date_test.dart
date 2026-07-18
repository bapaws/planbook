import 'package:flutter_planbook/discover/journal/model/journal_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planbook_core/view/flip_page_view.dart';

void main() {
  group('JournalDate with monthly pages', () {
    test('content page count for 2026', () {
      const date = JournalDate(year: 2026, month: 1, day: 1);
      // 2026 is not leap year: 365 * 2 + 12 * 4 = 778
      expect(date.contentPageCount, 778);
    });

    test('January highlight starts at content index 0', () {
      final highlight = JournalDate.monthHighlight(year: 2026, month: 1);
      expect(highlight.contentIndexStart, 0);
    });

    test('January 1 daily starts after highlight spread', () {
      const day = JournalDate(year: 2026, month: 1, day: 1);
      expect(day.contentIndexStart, 2);
    });

    test('January summary starts after all January daily pages', () {
      final summary = JournalDate.monthSummary(year: 2026, month: 1);
      // 2 (highlight) + 31 * 2 = 64
      expect(summary.contentIndexStart, 64);
    });

    test('February highlight follows January summary', () {
      final febHighlight = JournalDate.monthHighlight(year: 2026, month: 2);
      // 64 + 2 = 66
      expect(febHighlight.contentIndexStart, 66);
    });

    test('fromContentIndex round-trips all page kinds', () {
      final cases = [
        JournalDate.cover(2026),
        JournalDate.monthHighlight(year: 2026, month: 1),
        const JournalDate(year: 2026, month: 1, day: 15),
        JournalDate.monthSummary(year: 2026, month: 1),
        JournalDate.monthHighlight(year: 2026, month: 12),
        const JournalDate(year: 2026, month: 12, day: 31),
        JournalDate.monthSummary(year: 2026, month: 12),
        JournalDate.backCover(2026),
      ];
      for (final expected in cases) {
        final reconstructed = JournalDate.fromContentIndex(
          2026,
          expected.contentIndexStart,
        );
        expect(reconstructed, expected);
      }
    });

    test('previous/next navigate across month boundaries', () {
      const jan1 = JournalDate(year: 2026, month: 1, day: 1);
      expect(jan1.previous, JournalDate.monthHighlight(year: 2026, month: 1));
      expect(
        jan1.previous.previous,
        JournalDate.cover(2026),
      );

      final janSummary = JournalDate.monthSummary(year: 2026, month: 1);
      expect(
        janSummary.next,
        JournalDate.monthHighlight(year: 2026, month: 2),
      );
    });

    test('fromYear maps page index back to month highlight', () {
      final highlight = JournalDate.monthHighlight(year: 2026, month: 3);
      final reconstructed = JournalDate.fromYear(
        2026,
        pageIndex: highlight.pageIndex,
      );
      expect(reconstructed, highlight);
    });

    test('fromContentIndex returns highlight for both pages', () {
      final left = JournalDate.fromContentIndex(2026, 0);
      final right = JournalDate.fromContentIndex(2026, 1);
      expect(left, JournalDate.monthHighlight(year: 2026, month: 1));
      expect(right, JournalDate.monthHighlight(year: 2026, month: 1));
    });

    test('fromContentIndex returns summary for both pages', () {
      // January summary starts at 64 and occupies 64-65.
      final left = JournalDate.fromContentIndex(2026, 64);
      final right = JournalDate.fromContentIndex(2026, 65);
      expect(left, JournalDate.monthSummary(year: 2026, month: 1));
      expect(right, JournalDate.monthSummary(year: 2026, month: 1));
    });

    test('fromYear maps cover and backCover', () {
      expect(
        JournalDate.fromYear(2026, pageIndex: FlipPageIndex.cover),
        JournalDate.cover(2026),
      );
      expect(
        JournalDate.fromYear(
          2026,
          pageIndex: FlipPageIndex.fromLeft(778),
        ),
        JournalDate.backCover(2026),
      );
    });

    test('date getter returns exact day for daily pages', () {
      const day = JournalDate(year: 2026, month: 3, day: 15);
      expect(day.date.date, 15);
      expect(day.date.month, 3);
    });

    test('date getter returns month start for monthly pages', () {
      final highlight = JournalDate.monthHighlight(year: 2026, month: 5);
      final summary = JournalDate.monthSummary(year: 2026, month: 5);
      expect(highlight.date.date, 1);
      expect(highlight.date.month, 5);
      expect(summary.date.date, 1);
      expect(summary.date.month, 5);
    });
  });
}
