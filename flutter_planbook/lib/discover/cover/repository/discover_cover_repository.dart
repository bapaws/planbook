import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverCoverRepository {
  DiscoverCoverRepository({
    required SupabaseClient? supabase,
    required AssetsRepository assetsRepository,
  }) : _supabase = supabase,
       _assetsRepository = assetsRepository;

  final SupabaseClient? _supabase;
  final AssetsRepository _assetsRepository;

  static const String _defaultCover = 'assets/images/cover.jpg';

  String? get _userId => _supabase?.auth.currentUser?.id;

  Future<String> getYearCoverPath(int year) async {
    final userId = _userId;
    if (userId == null) return _defaultCover;
    final yearKey = '$year';
    await UsersRepository.instance.getUserProfile();
    final fromProfile =
        UsersRepository.instance.userProfile?.coverByYear[yearKey];
    if (fromProfile != null && fromProfile.isNotEmpty) {
      return fromProfile;
    }
    return _defaultCover;
  }

  Future<void> saveYearCoverPath({
    required int year,
    required String coverPath,
  }) async {
    await UsersRepository.instance.updateJournalCoverForYear(
      year: year,
      coverPath: coverPath,
    );
  }

  ImageProvider<Object> imageProviderFor(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    if (path.startsWith(AssetsRepository.host)) {
      return SupaStorageImageProvider(
        url: path,
        repository: _assetsRepository,
      );
    }
    if (path.startsWith('https://')) {
      return CachedNetworkImageProvider(path);
    }
    return FileImage(File(path));
  }
}
