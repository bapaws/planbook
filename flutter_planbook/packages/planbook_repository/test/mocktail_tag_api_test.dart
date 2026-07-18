import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTagApi extends Mock implements DatabaseTagApi {}

void main() {
  test('mocktail with DatabaseTagApi', () async {
    final mock = MockTagApi();
    when(
      () => mock.getTotalCount(userId: any(named: 'userId')),
    ).thenAnswer((_) async => 5);
    final result = await mock.getTotalCount(userId: null);
    expect(result, 5);
  });
}
