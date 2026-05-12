import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/recurrence_rule.dart';

import 'package:database_planbook_api/task/recurrence_rule_calculator.dart';

void main() {
  group('RecurrenceRuleCalculator', () {
    final startDate = Jiffy.parse('2024-01-01');

    group('shouldOccurOnDate', () {
      test('returns false when targetDate is before startDate', () {
        final rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
        final targetDate = Jiffy.parse('2023-12-31');

        expect(
          RecurrenceRuleCalculator.shouldOccurOnDate(
            rule: rule,
            startDate: startDate,
            targetDate: targetDate,
          ),
          isFalse,
        );
      });

      test('returns false when targetDate is after endAt', () {
        final rule = RecurrenceRule.withEndAt(
          frequency: RecurrenceFrequency.daily,
          endAt: Jiffy.parse('2024-01-05'),
        );
        final targetDate = Jiffy.parse('2024-01-06');

        expect(
          RecurrenceRuleCalculator.shouldOccurOnDate(
            rule: rule,
            startDate: startDate,
            targetDate: targetDate,
          ),
          isFalse,
        );
      });

      group('daily', () {
        test('returns true for every day when interval is 1', () {
          final rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-05'),
            ),
            isTrue,
          );
        });

        test('returns true only every other day when interval is 2', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 2,
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-02'),
            ),
            isFalse,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-03'),
            ),
            isTrue,
          );
        });

        test('returns false when occurrence count is exceeded', () {
          final rule = RecurrenceRule.withOccurrenceCount(
            frequency: RecurrenceFrequency.daily,
            occurrenceCount: 3,
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-03'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-04'),
            ),
            isFalse,
          );
        });
      });

      group('weekly', () {
        test('returns true for matching weekday without daysOfWeek', () {
          final rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);

          // 2024-01-01 is Monday, so every Monday
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-08'),
            ),
            isTrue,
          );
        });

        test('returns false when weekday does not match daysOfWeek', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.monday),
            ],
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-02'),
            ),
            isFalse,
          );
        });

        test('returns false when weeksDiff is not divisible by interval', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            interval: 2,
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.monday),
            ],
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-08'),
            ),
            isFalse,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-15'),
            ),
            isTrue,
          );
        });

        test('returns false when occurrence count is exceeded for weekly', () {
          final rule = RecurrenceRule.withOccurrenceCount(
            frequency: RecurrenceFrequency.weekly,
            occurrenceCount: 2,
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-08'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-15'),
            ),
            isFalse,
          );
        });
      });

      group('monthly', () {
        test('returns true for matching month with interval 1', () {
          final rule = RecurrenceRule(frequency: RecurrenceFrequency.monthly);

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-02-01'),
            ),
            isTrue,
          );
        });

        test('returns false when monthsDiff is not divisible by interval', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 2,
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-03-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-02-01'),
            ),
            isFalse,
          );
        });

        test('returns false when occurrence count exceeded for monthly', () {
          final rule = RecurrenceRule.withOccurrenceCount(
            frequency: RecurrenceFrequency.monthly,
            occurrenceCount: 2,
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-02-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-03-01'),
            ),
            isFalse,
          );
        });

        test('returns false when daysOfMonth does not match', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfMonth: [15],
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-15'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isFalse,
          );
        });

        test(
            'returns true when daysOfWeek and weeksOfMonth with weekNumber match',
            () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfWeek: [
              RecurrenceDayOfWeek.dayWithWeekNumber(Weekday.monday, 1),
            ],
            weeksOfMonth: [1],
          );

          // 2024-01-01 is the first Monday
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          // 2024-01-08 is the second Monday
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-08'),
            ),
            isFalse,
          );
        });

        test(
            'returns true when daysOfWeek and weeksOfMonth without weekNumber match',
            () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.monday),
            ],
            weeksOfMonth: [1],
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
        });

        test(
            'returns true for last week of month when weeksOfMonth contains -1',
            () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.monday),
            ],
            weeksOfMonth: [-1],
          );

          // 2024-01-29 is the last Monday of January 2024
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-29'),
            ),
            isTrue,
          );
          // 2024-01-01 is the first Monday
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isFalse,
          );
        });

        test('returns false when only daysOfWeek does not match', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.monday),
            ],
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-02'),
            ),
            isFalse,
          );
        });
      });

      group('yearly', () {
        test('returns true for matching year with interval 1', () {
          final rule = RecurrenceRule(frequency: RecurrenceFrequency.yearly);

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2025-01-01'),
            ),
            isTrue,
          );
        });

        test('returns false when yearsDiff is not divisible by interval', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.yearly,
            interval: 2,
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2026-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2025-01-01'),
            ),
            isFalse,
          );
        });

        test('returns false when occurrence count exceeded for yearly', () {
          final rule = RecurrenceRule.withOccurrenceCount(
            frequency: RecurrenceFrequency.yearly,
            occurrenceCount: 2,
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2025-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2026-01-01'),
            ),
            isFalse,
          );
        });

        test('returns false when daysOfYear does not match', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.yearly,
            daysOfYear: [101], // Jan 1
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-02-01'),
            ),
            isFalse,
          );
        });

        test(
            'returns true when daysOfWeek and weeksOfMonth match for yearly',
            () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.yearly,
            daysOfWeek: [
              RecurrenceDayOfWeek.dayWithWeekNumber(Weekday.monday, 1),
            ],
            weeksOfMonth: [1],
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
        });

        test(
            'returns true for last week when weeksOfMonth contains -1 for yearly',
            () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.yearly,
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.monday),
            ],
            weeksOfMonth: [-1],
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-29'),
            ),
            isTrue,
          );
        });

        test('returns false when only daysOfWeek does not match for yearly',
            () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.yearly,
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.monday),
            ],
          );

          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-01'),
            ),
            isTrue,
          );
          expect(
            RecurrenceRuleCalculator.shouldOccurOnDate(
              rule: rule,
              startDate: startDate,
              targetDate: Jiffy.parse('2024-01-02'),
            ),
            isFalse,
          );
        });
      });
    });

    group('generateOccurrences', () {
      test('adjusts rangeStart to startDate when it is before startDate', () {
        final rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
        final rangeStart = Jiffy.parse('2023-12-30');
        final rangeEnd = Jiffy.parse('2024-01-03');

        final occurrences = RecurrenceRuleCalculator.generateOccurrences(
          rule: rule,
          startDate: startDate,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        expect(occurrences.length, 3);
        expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-01');
        expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-02');
        expect(occurrences[2].format(pattern: 'yyyy-MM-dd'), '2024-01-03');
      });

      test('returns empty list when rangeStart is after endAt', () {
        final rule = RecurrenceRule.withEndAt(
          frequency: RecurrenceFrequency.daily,
          endAt: Jiffy.parse('2024-01-05'),
        );
        final rangeStart = Jiffy.parse('2024-01-10');
        final rangeEnd = Jiffy.parse('2024-01-15');

        final occurrences = RecurrenceRuleCalculator.generateOccurrences(
          rule: rule,
          startDate: startDate,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        expect(occurrences, isEmpty);
      });

      test('limits rangeEnd to endAt when rangeEnd exceeds endAt', () {
        final rule = RecurrenceRule.withEndAt(
          frequency: RecurrenceFrequency.daily,
          endAt: Jiffy.parse('2024-01-05'),
        );
        final rangeStart = Jiffy.parse('2024-01-01');
        final rangeEnd = Jiffy.parse('2024-01-10');

        final occurrences = RecurrenceRuleCalculator.generateOccurrences(
          rule: rule,
          startDate: startDate,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        expect(occurrences.length, 5);
        expect(occurrences.last.format(pattern: 'yyyy-MM-dd'), '2024-01-05');
      });

      group('daily', () {
        test('generates every day with interval 1', () {
          final rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2024-01-05');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(occurrences.length, 5);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-01');
          expect(occurrences[4].format(pattern: 'yyyy-MM-dd'), '2024-01-05');
        });

        test('generates every other day with interval 2', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 2,
          );
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2024-01-10');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(occurrences.length, 5);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-01');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-03');
          expect(occurrences[4].format(pattern: 'yyyy-MM-dd'), '2024-01-09');
        });

        test('adjusts to first matching date when rangeStart is not aligned',
            () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 3,
          );
          final rangeStart = Jiffy.parse('2024-01-02');
          final rangeEnd = Jiffy.parse('2024-01-10');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          // 2024-01-01, 2024-01-04, 2024-01-07, 2024-01-10
          expect(occurrences.length, 3);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-04');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-07');
          expect(occurrences[2].format(pattern: 'yyyy-MM-dd'), '2024-01-10');
        });

        test('stops at occurrence count limit', () {
          final rule = RecurrenceRule.withOccurrenceCount(
            frequency: RecurrenceFrequency.daily,
            occurrenceCount: 3,
          );
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2024-01-10');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(occurrences.length, 3);
          expect(occurrences.last.format(pattern: 'yyyy-MM-dd'), '2024-01-03');
        });
      });

      group('weekly', () {
        test('generates matching weekdays when daysOfWeek is specified', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            daysOfWeek: [
              RecurrenceDayOfWeek.day(Weekday.monday),
              RecurrenceDayOfWeek.day(Weekday.wednesday),
            ],
          );
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2024-01-10');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          // 2024-01-01 Mon, 2024-01-03 Wed, 2024-01-08 Mon, 2024-01-10 Wed
          expect(occurrences.length, 4);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-01');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-03');
          expect(occurrences[2].format(pattern: 'yyyy-MM-dd'), '2024-01-08');
          expect(occurrences[3].format(pattern: 'yyyy-MM-dd'), '2024-01-10');
        });

        test('generates weekly dates without daysOfWeek', () {
          final rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2024-01-15');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(occurrences.length, 3);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-01');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-08');
          expect(occurrences[2].format(pattern: 'yyyy-MM-dd'), '2024-01-15');
        });

        test(
            'adjusts to first matching week when rangeStart is not aligned',
            () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            interval: 2,
          );
          final rangeStart = Jiffy.parse('2024-01-15');
          final rangeEnd = Jiffy.parse('2024-01-29');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          // startDate=2024-01-01, interval=2
          // 2024-01-15 (weeksDiff=2) and 2024-01-29 (weeksDiff=4)
          expect(occurrences.length, 2);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-15');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-29');
        });

        test(
            'adjusts from unaligned rangeStart with remainder for weekly without daysOfWeek',
            () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            interval: 2,
          );
          // 2024-01-08 is 1 week from startDate, remainder=1 when interval=2
          final rangeStart = Jiffy.parse('2024-01-08');
          final rangeEnd = Jiffy.parse('2024-01-31');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          // Adjusted to 2024-01-15 (weeksDiff=2), then 2024-01-29 (weeksDiff=4)
          expect(occurrences.length, 2);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-15');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-29');
        });

        test('stops at occurrence count limit for weekly', () {
          final rule = RecurrenceRule.withOccurrenceCount(
            frequency: RecurrenceFrequency.weekly,
            occurrenceCount: 2,
          );
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2024-01-31');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(occurrences.length, 2);
          expect(occurrences.last.format(pattern: 'yyyy-MM-dd'), '2024-01-08');
        });
      });

      group('monthly', () {
        test('generates matching daysOfMonth', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfMonth: [1, 15],
          );
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2024-03-15');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(occurrences.length, 6);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-01');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-15');
          expect(occurrences[2].format(pattern: 'yyyy-MM-dd'), '2024-02-01');
          expect(occurrences[3].format(pattern: 'yyyy-MM-dd'), '2024-02-15');
          expect(occurrences[4].format(pattern: 'yyyy-MM-dd'), '2024-03-01');
          expect(occurrences[5].format(pattern: 'yyyy-MM-dd'), '2024-03-15');
        });

        test('generates monthly dates without daysOfMonth', () {
          // Without daysOfMonth, every day in the same month matches
          // because monthsDiff is 0 and 0 % 1 == 0.
          final rule = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2024-01-03');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(occurrences.length, 3);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-01');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-02');
          expect(occurrences[2].format(pattern: 'yyyy-MM-dd'), '2024-01-03');
        });
      });

      group('yearly', () {
        test('generates yearly dates', () {
          // Without daysOfYear, every day in the same year matches
          // because yearsDiff is 0 and 0 % 1 == 0.
          final rule = RecurrenceRule(frequency: RecurrenceFrequency.yearly);
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2024-01-03');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(occurrences.length, 3);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-01');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2024-01-02');
          expect(occurrences[2].format(pattern: 'yyyy-MM-dd'), '2024-01-03');
        });

        test('generates yearly dates with daysOfYear filter', () {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.yearly,
            daysOfYear: [101], // Jan 1
          );
          final rangeStart = Jiffy.parse('2024-01-01');
          final rangeEnd = Jiffy.parse('2025-01-01');

          final occurrences = RecurrenceRuleCalculator.generateOccurrences(
            rule: rule,
            startDate: startDate,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(occurrences.length, 2);
          expect(occurrences[0].format(pattern: 'yyyy-MM-dd'), '2024-01-01');
          expect(occurrences[1].format(pattern: 'yyyy-MM-dd'), '2025-01-01');
        });
      });
    });
  });
}
