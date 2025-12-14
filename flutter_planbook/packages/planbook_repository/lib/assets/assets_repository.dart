import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:planbook_api/planbook_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum ResBucket {
  noteImages,
  userAvatars;

  String get name => switch (this) {
    ResBucket.noteImages => 'planbook-note-images',
    ResBucket.userAvatars => 'user-avatars',
  };
}

/// {@template planbook_repository}
/// A repository that handles planbook related requests.
/// {@endtemplate}
class AssetsRepository {
  /// {@macro planbook_repository}
  AssetsRepository({
    required SupabaseClient? supabase,
    required AppDatabase db,
    CacheManager? cacheManager,
  }) : _supabase = supabase,
       _cacheManager = cacheManager ?? DefaultCacheManager(),
       _db = db;

  /// The supabase client for this instance
  ///
  /// Throws an error if [Supabase.initialize] was not called.
  final SupabaseClient? _supabase;

  /// The cache manager for this instance
  final CacheManager _cacheManager;

  final AppDatabase _db;

  static const _host = 'https://supa.res.bapaws.top';
  static const _folder = 'planbook';

  String? get userId => _supabase?.auth.currentUser?.id;

  Future<Uint8List?> downloadImage(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final bucketName = uri.pathSegments.firstOrNull;
    if (bucketName == null) return null;

    final bucket = ResBucket.values.firstWhereOrNull(
      (e) => e.name == bucketName,
    );
    if (bucket == null) return null;

    final fileInfo = await _cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      return fileInfo.file.readAsBytesSync();
    }
    try {
      final res = await _supabase?.storage
          .from(bucketName)
          .download(getFileName(bucket, url));
      if (res == null) return null;

      await _cacheManager.putFile(url, res);
      return res;
    } on StorageException catch (e) {
      log(e.toString());
      return null;
    }
  }

  String getFileName(ResBucket bucket, String url) {
    final bucketName = bucket.name;
    if (url.contains(bucketName)) {
      return url.substring(
        url.lastIndexOf(bucketName) + bucketName.length + 1,
      );
    }
    return p.join(userId ?? _folder, url);
  }

  Future<void> removeImages(List<String> urls, ResBucket bucket) async {
    if (urls.isEmpty) return;

    await Future.wait(
      urls.map(
        _cacheManager.removeFile,
      ),
    );
    await _supabase?.storage
        .from(bucket.name)
        .remove(urls.map((e) => getFileName(bucket, e)).toList());
  }

  Future<String> uploadImage(String path, ResBucket bucket) async {
    if (path.startsWith('http')) {
      return path;
    }
    final fileName = getFileName(
      bucket,
      '${const Uuid().v4()}.${path.split('.').last}',
    );
    final url = '$_host/${bucket.name}/$fileName';

    final file = File(path);

    unawaited(() async {
      final fileBytes = await file.readAsBytes();
      await _cacheManager.putFile(url, fileBytes);
    }());

    await _supabase?.storage.from(bucket.name).upload(fileName, file);

    return url;
  }
}
