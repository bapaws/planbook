import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:planbook_repository/assets/assets_repository.dart';
import 'package:planbook_repository/assets/supa_storage_image_provider.dart';

ImageProvider<Object> imageProviderForPath(
  String path, {
  AssetsRepository? assetsRepository,
}) {
  if (path.startsWith('assets/')) {
    return AssetImage(path);
  }
  if (path.startsWith(AssetsRepository.host) && assetsRepository != null) {
    return SupaStorageImageProvider(url: path, repository: assetsRepository);
  }
  if (path.startsWith('https://')) {
    return CachedNetworkImageProvider(path);
  }
  return FileImage(File(path));
}
