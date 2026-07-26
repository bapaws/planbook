import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_api/planbook_api.dart';

class _FakeTaskEntity extends TaskEntity {
  _FakeTaskEntity({required super.task});
}

Task _fakeTask({required String id, required String title}) => Task(
  id: id,
  title: title,
  layer: 0,
  childCount: 0,
  order: 0,
  isAllDay: false,
  alarms: const [],
  createdAt: Jiffy.now(),
);

void main() {
  testWidgets('SliverTaskDragTarget accepts drop from external Draggable', (
    tester,
  ) async {
    TaskEntity? acceptedTask;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      sliver: SliverCrossAxisGroup(
                        slivers: [
                          const SliverConstrainedCrossAxis(
                            maxExtent: 64,
                            sliver: SliverToBoxAdapter(
                              child: Center(child: Text('Header')),
                            ),
                          ),
                          SliverTaskDragTarget(
                            onAccept: (task) => acceptedTask = task,
                            sliver: SliverToBoxAdapter(
                              child: Container(
                                height: 400,
                                color: Colors.red,
                                child: const Center(child: Text('Target')),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: Center(
                  child: LongPressDraggable<TaskEntity>(
                    data: _FakeTaskEntity(
                      task: _fakeTask(id: 't1', title: 'Drag me'),
                    ),
                    feedback: const Material(
                      child: Text('feedback'),
                    ),
                    child: const Text('Source'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final sourceFinder = find.text('Source');
    expect(sourceFinder, findsOneWidget);

    // Start a long-press gesture, wait for it to win, then drag to target.
    final sourceCenter = tester.getCenter(sourceFinder);
    final gesture = await tester.startGesture(sourceCenter);
    await tester.pump(kLongPressTimeout);
    final targetRect = tester.getRect(find.text('Target'));
    await gesture.moveBy(targetRect.center - sourceCenter);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(acceptedTask, isNotNull);
    expect(acceptedTask!.title, 'Drag me');
  });

  testWidgets(
    'SliverTaskDragTarget wrapping CrossAxisGroup accepts drop on blank '
    'beside taller header when tasks are short',
    (tester) async {
      TaskEntity? acceptedTask;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverTaskDragTarget(
                        onAccept: (task) => acceptedTask = task,
                        sliver: SliverCrossAxisGroup(
                          slivers: [
                            const SliverConstrainedCrossAxis(
                              maxExtent: 64,
                              sliver: SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 72,
                                  child: Center(child: Text('Header')),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Container(
                                height: 36,
                                color: Colors.green,
                                child: const Center(child: Text('Short')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Center(
                    child: LongPressDraggable<TaskEntity>(
                      data: _FakeTaskEntity(
                        task: _fakeTask(id: 't1', title: 'Drag me'),
                      ),
                      feedback: const Material(child: Text('feedback')),
                      child: const Text('Source'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final sourceCenter = tester.getCenter(find.text('Source'));
      final headerRect = tester.getRect(find.text('Header'));
      // 日期头旁、短任务下方的视觉空白
      final blank = Offset(headerRect.right + 40, headerRect.bottom - 8);

      final gesture = await tester.startGesture(sourceCenter);
      await tester.pump(kLongPressTimeout);
      await gesture.moveBy(blank - sourceCenter);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(acceptedTask, isNotNull);
      expect(acceptedTask!.title, 'Drag me');
    },
  );
}
