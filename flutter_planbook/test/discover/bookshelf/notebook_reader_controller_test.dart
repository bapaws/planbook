import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_reader_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_notebook/paper_notebook.dart';

void main() {
  testWidgets('取消日记翻页手势后等待方收到空闲通知', (tester) async {
    final controller = PaperNotebookController();
    final reader = NotebookReaderController();
    addTearDown(controller.dispose);
    addTearDown(reader.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: PaperNotebook(
          controller: controller,
          coverClosed: false,
          pageCount: 3,
          pageBuilder: (_, index) => ColoredBox(
            key: ValueKey('page-$index'),
            color: Colors.white,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(const ValueKey('page-0')));
    final gesture = await tester.startGesture(
      Offset(rect.right - 24, rect.center.dy),
    );
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    expect(controller.isAnimating, isTrue);
    var idle = false;
    unawaited(
      reader.waitForIdle(controller, () => controller.isAnimating).then((_) {
        idle = true;
      }),
    );
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(controller.index, 0);
    expect(controller.isAnimating, isFalse);
    expect(idle, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
