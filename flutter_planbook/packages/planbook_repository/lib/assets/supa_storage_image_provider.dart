import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planbook_repository/assets/assets_repository.dart';

/// Custom [ImageProvider] that loads images from Supabase Storage via
/// [AssetsRepository.downloadImage], instead of relying on public HTTP access.
@immutable
class SupaStorageImageProvider extends ImageProvider<SupaStorageImageProvider> {
  SupaStorageImageProvider({
    required this.url,
    required this.repository,
  });

  final String url;
  final AssetsRepository repository;

  @override
  Future<SupaStorageImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    // Use `url` as the cache key for Flutter's ImageCache.
    // `repository` is only used to actually fetch bytes.
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    SupaStorageImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  Future<ImageInfo> _loadAsync(
    SupaStorageImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await key.repository.downloadImage(key.url);
    if (bytes == null) {
      throw StateError('Unable to load image bytes: ${key.url}');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await decode(buffer);
    final frameInfo = await codec.getNextFrame();
    return ImageInfo(image: frameInfo.image);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupaStorageImageProvider && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
