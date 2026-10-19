import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planbook_core/planbook_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('合并相同会员刷新，账号或权益变化仍刷新，失败可以重试', () async {
    const channel = MethodChannel('home_widget');
    final calls = <MethodCall>[];
    var failSave = false;
    var failUpdate = false;
    final firstSave = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'saveWidgetData') {
            if (!firstSave.isCompleted) await firstSave.future;
            return !failSave;
          }
          if (call.method == 'updateWidget' && failUpdate) {
            throw PlatformException(code: 'update_failed');
          }
          return true;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final first = AppHomeWidget.syncPremium(isPremium: true, userId: 'a');
    final duplicate = AppHomeWidget.syncPremium(isPremium: true, userId: 'a');
    firstSave.complete();
    await Future.wait([first, duplicate]);
    expect(
      calls.where((call) => call.method == 'saveWidgetData'),
      hasLength(1),
    );
    expect(calls.where((call) => call.method == 'updateWidget'), hasLength(3));

    await AppHomeWidget.syncPremium(isPremium: true, userId: 'b');
    await AppHomeWidget.syncPremium(isPremium: false, userId: 'b');
    expect(calls.where((call) => call.method == 'updateWidget'), hasLength(9));

    failSave = true;
    await AppHomeWidget.syncPremium(isPremium: true, userId: 'b');
    failSave = false;
    await AppHomeWidget.syncPremium(isPremium: true, userId: 'b');
    expect(calls.where((call) => call.method == 'updateWidget'), hasLength(12));
    failUpdate = true;
    await AppHomeWidget.syncPremium(isPremium: false, userId: 'b');
    failUpdate = false;
    await AppHomeWidget.syncPremium(isPremium: false, userId: 'b');
    expect(calls.where((call) => call.method == 'updateWidget'), hasLength(18));
  });
}
