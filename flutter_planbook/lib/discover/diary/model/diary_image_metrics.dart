import 'dart:async';
import 'dart:collection';

import 'package:flutter/painting.dart';

/// 按需读取当前篇及相邻篇的照片比例，最多并发三张，不预载整本相册。
class DiaryImageMetrics {
  final Map<String, double> ratios = {};
  final Set<String> _finished = {};
  final Map<String, _ImageRequest> _requests = {};
  final Queue<_ImageRequest> _queue = Queue();
  final Set<_ImageRequest> _active = {};
  bool _disposed = false;

  bool isReady(Iterable<String> paths) => paths.every(_finished.contains);

  Future<void> prepare(
    Iterable<String> paths, {
    required ImageProvider<Object> Function(String) providerForPath,
    required ImageConfiguration configuration,
  }) => Future.wait([
    for (final path in paths)
      if (!_finished.contains(path))
        _request(path, providerForPath, configuration),
  ]);

  Future<void> _request(
    String path,
    ImageProvider<Object> Function(String) providerForPath,
    ImageConfiguration configuration,
  ) {
    if (_disposed) return Future.value();
    if (_requests[path] case final request?) return request.done.future;
    final request = _ImageRequest(path, providerForPath, configuration);
    _requests[path] = request;
    request.timeout = Timer(const Duration(seconds: 4), () => _finish(request));
    _queue.add(request);
    _pump();
    return request.done.future;
  }

  void _pump() {
    while (!_disposed && _active.length < 3 && _queue.isNotEmpty) {
      final request = _queue.removeFirst();
      _active.add(request);
      try {
        // fit 保持原图比例，小尺寸解码避免为测量长期占用原图内存。
        final stream = ResizeImage(
          request.providerForPath(request.path),
          width: 320,
          height: 320,
          policy: ResizeImagePolicy.fit,
        ).resolve(request.configuration);
        request.stream = stream;
        final listener = ImageStreamListener(
          (info, synchronousCall) {
            final ratio = info.image.width / info.image.height;
            info.dispose();
            _finish(request, ratio.isFinite && ratio > 0 ? ratio : null);
          },
          onError: (Object error, StackTrace? stack) => _finish(request),
        );
        request.listener = listener;
        stream.addListener(listener);
      } on Object {
        _finish(request);
      }
    }
  }

  void _finish(_ImageRequest request, [double? ratio]) {
    if (_requests.remove(request.path) != request) return;
    _active.remove(request);
    _queue.remove(request);
    request.release();
    _finished.add(request.path);
    if (ratio != null) ratios[request.path] = ratio;
    request.done.complete();
    _pump();
  }

  void dispose() {
    _disposed = true;
    for (final request in _requests.values) {
      request.release();
      if (!request.done.isCompleted) request.done.complete();
    }
    _requests.clear();
    _queue.clear();
    _active.clear();
  }
}

class _ImageRequest {
  _ImageRequest(this.path, this.providerForPath, this.configuration);

  final String path;
  final ImageProvider<Object> Function(String) providerForPath;
  final ImageConfiguration configuration;
  final Completer<void> done = Completer();
  ImageStream? stream;
  ImageStreamListener? listener;
  Timer? timeout;

  void release() {
    timeout?.cancel();
    if (listener case final listener?) stream?.removeListener(listener);
  }
}
