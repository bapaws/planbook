import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_bookshelf.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('左右滑动切换不同本子，点击后打开当前本子', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    NotebookKind? opened;
    NotebookKind? selected;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotebookBookshelf(
            onOpen: (kind) => opened = kind,
            onSelected: (kind) => selected = kind,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(opened, isNull);
    expect(find.text('PRO'), findsNothing);
    await tester.drag(
      find.byKey(const Key('notebook-bookshelf')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();
    expect(selected, NotebookKind.diary);
    expect(find.text('PRO'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(opened, NotebookKind.diary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('小屏和大字号仍可浏览并重新打开所选本子', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    NotebookKind? opened;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Notebooks')),
          body: NotebookBookshelf(
            selected: NotebookKind.diary,
            onOpen: (kind) => opened = kind,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Open'));
    expect(opened, NotebookKind.diary);
  });
}
