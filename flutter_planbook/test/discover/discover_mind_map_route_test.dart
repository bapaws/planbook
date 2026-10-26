import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planbook_api/planbook_api.dart';

void main() {
  for (final type in NoteType.values.where((type) => !type.isJournal)) {
    test('任务页的 ${type.name} 入口匹配完整思维导图路由', () {
      final router = AppRouter();
      addTearDown(router.dispose);
      final match = router.matcher.matchByRoute(discoverMindMapRoute(type));
      expect(match, isNotNull);
      final discover = match!.children!.single;
      expect(discover.name, RootDiscoverRoute.name);
      final browse = discover.children!.single;
      expect(browse.name, DiscoverBrowseRoute.name);
      expect(
        browse.children!.single.name,
        type.isFocus ? DiscoverFocusRoute.name : DiscoverSummaryRoute.name,
      );
    });
  }
}
