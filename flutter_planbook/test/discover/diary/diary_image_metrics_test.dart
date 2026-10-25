import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_planbook/discover/diary/model/diary_image_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

class _ImageProvider extends ImageProvider<_ImageProvider> {
  final Completer<ImageInfo> image = Completer();

  @override
  Future<_ImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _ImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(image.future);
}

void main() {
  testWidgets('比例读取限制三张并发、复用同一请求，完成后保留横竖比例', (tester) async {
    final metrics = DiaryImageMetrics();
    addTearDown(metrics.dispose);
    final image = (await tester.runAsync(
      () => createTestImage(width: 240, height: 80),
    ))!;
    addTearDown(image.dispose);
    final providers = <String, _ImageProvider>{};
    ImageProvider<Object> provider(String path) =>
        providers.putIfAbsent(path, _ImageProvider.new);
    final paths = List.generate(9, (i) => 'photo-$i');
    final ready = metrics.prepare(
      paths,
      providerForPath: provider,
      configuration: ImageConfiguration.empty,
    );
    final same = metrics.prepare(
      paths,
      providerForPath: provider,
      configuration: ImageConfiguration.empty,
    );
    expect(providers, hasLength(3));
    for (var batch = 0; batch < 3; batch++) {
      for (final path in paths.skip(batch * 3).take(3)) {
        providers[path]!.image.complete(ImageInfo(image: image.clone()));
      }
      await tester.pump();
      expect(providers.length, (batch + 2).clamp(0, 3) * 3);
    }
    await ready;
    await same;
    expect(metrics.isReady(paths), isTrue);
    expect(metrics.ratios.values, everyElement(3.0));
    await metrics.prepare(
      paths,
      providerForPath: (_) => throw StateError('不能重复读取'),
      configuration: ImageConfiguration.empty,
    );
  });

  testWidgets('损坏及排队超时的照片不会卡住整篇日记', (tester) async {
    final metrics = DiaryImageMetrics();
    addTearDown(metrics.dispose);
    final providers = <String, _ImageProvider>{};
    final paths = List.generate(9, (i) => 'missing-$i');
    final ready = metrics.prepare(
      paths,
      providerForPath: (path) =>
          providers.putIfAbsent(path, _ImageProvider.new),
      configuration: ImageConfiguration.empty,
    );
    providers[paths.first]!.image.completeError(StateError('图片失效'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await ready;
    expect(metrics.isReady(paths), isTrue);
    expect(metrics.ratios, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('关闭阅读器会释放测量请求，等待方可以正常结束', (tester) async {
    final metrics = DiaryImageMetrics();
    final paths = List.generate(9, (i) => 'pending-$i');
    var started = 0;
    final ready = metrics.prepare(
      paths,
      providerForPath: (_) {
        started++;
        return _ImageProvider();
      },
      configuration: ImageConfiguration.empty,
    );
    expect(started, 3);
    metrics.dispose();
    await ready;
    await tester.pump(const Duration(seconds: 5));
    expect(started, 3);
    expect(tester.takeException(), isNull);
  });
}
