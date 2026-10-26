import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/note/new/cubit/note_new_cubit.dart';
import 'package:flutter_planbook/note/new/view/note_new_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _NoteCubit extends MockCubit<NoteNewState> implements NoteNewCubit {}

class _PurchasesBloc extends MockBloc<AppPurchasesEvent, AppPurchasesState>
    implements AppPurchasesBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/image_picker');
  late _NoteCubit cubit;
  late _PurchasesBloc purchases;
  late List<MethodCall> calls;
  Object? pickerResult;

  setUp(() {
    cubit = _NoteCubit();
    purchases = _PurchasesBloc();
    when(() => purchases.isPremium).thenReturn(true);
    when(() => cubit.addImages(any())).thenAnswer((_) async {});
    calls = [];
    pickerResult = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return pickerResult;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> mount(WidgetTester tester, int count) async {
    when(() => cubit.state).thenReturn(
      NoteNewState(images: List.generate(count, (i) => 'image-$i.jpg')),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<NoteNewCubit>.value(value: cubit),
          BlocProvider<AppPurchasesBloc>.value(value: purchases),
        ],
        child: const MaterialApp(
          home: Scaffold(body: NoteNewBottomBar()),
        ),
      ),
    );
  }

  testWidgets('已有八张图片时使用相册单选补足第九张', (tester) async {
    pickerResult = '/tmp/ninth.jpg';
    await mount(tester, 8);
    await tester.tap(find.byType(CupertinoButton).first);
    await tester.pumpAndSettle();
    expect(calls.single.method, 'pickImage');
    expect((calls.single.arguments as Map)['source'], 1);
    verify(() => cubit.addImages(['/tmp/ninth.jpg'])).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('只剩一个名额时取消相册不会添加图片', (tester) async {
    await mount(tester, 8);
    await tester.tap(find.byType(CupertinoButton).first);
    await tester.pumpAndSettle();
    expect(calls.single.method, 'pickImage');
    verifyNever(() => cubit.addImages(any()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('剩余两个名额时继续使用带上限的多选', (tester) async {
    pickerResult = ['/tmp/eighth.jpg', '/tmp/ninth.jpg'];
    await mount(tester, 7);
    await tester.tap(find.byType(CupertinoButton).first);
    await tester.pumpAndSettle();
    expect(calls.single.method, 'pickMultiImage');
    expect((calls.single.arguments as Map)['limit'], 2);
    verify(
      () => cubit.addImages(['/tmp/eighth.jpg', '/tmp/ninth.jpg']),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('已有九张图片时禁用相册和拍照', (tester) async {
    await mount(tester, 9);
    final buttons = tester.widgetList<CupertinoButton>(
      find.byType(CupertinoButton),
    );
    expect(
      buttons.take(2).map((button) => button.onPressed),
      everyElement(isNull),
    );
    expect(calls, isEmpty);
    verifyNever(() => cubit.addImages(any()));
  });
}
