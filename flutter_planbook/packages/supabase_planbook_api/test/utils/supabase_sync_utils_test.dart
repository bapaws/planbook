import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_planbook_api/utils/supabase_sync_utils.dart';

void main() {
  group('maxTimestampFromSyncItems', () {
    test('returns null for empty list', () {
      expect(maxTimestampFromSyncItems([]), isNull);
    });

    test('returns null when items have no time fields', () {
      expect(
        maxTimestampFromSyncItems([
          {'id': 'a'},
          {'id': 'b', 'title': 'x'},
        ]),
        isNull,
      );
    });

    test('returns max of updated_at, created_at, and deleted_at', () {
      final early = DateTime.utc(2024, 1, 1).millisecondsSinceEpoch;
      final mid = DateTime.utc(2024, 6, 15).millisecondsSinceEpoch;
      final late = DateTime.utc(2024, 12, 31).millisecondsSinceEpoch;

      final result = maxTimestampFromSyncItems([
        {
          'updated_at': DateTime.utc(2024, 1, 1).toIso8601String(),
          'created_at': DateTime.utc(2024, 6, 15).toIso8601String(),
        },
        {
          'deleted_at': DateTime.utc(2024, 12, 31).toIso8601String(),
        },
      ]);

      expect(result, late);
      expect(result, greaterThan(mid));
      expect(result, greaterThan(early));
    });
  });
}
