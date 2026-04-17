import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_planbook/app/activity/repository/app_store_repository.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ActivityPlatform {
  ios,
  android,
}

class ActivityMessageEntity {
  const ActivityMessageEntity({
    required this.id,
    required this.emoji,
    required this.title,
    this.languageCode = 'en',
    this.content,
    this.contentURL,
    this.openURL,
    this.openTitle,
    this.illustration,
    this.receiveWay,
    this.isNotPro = true,
    this.startAt,
    this.endAt,
    this.platforms = const [ActivityPlatform.ios],
    this.isNew = false,
  });

  factory ActivityMessageEntity.fromJson(Map<String, dynamic> json) {
    return ActivityMessageEntity(
      id: json['id'] as int,
      emoji: json['emoji'] as String,
      title: json['title'] as String,
      languageCode: json['languageCode'] as String? ?? 'en',
      content: json['content'] as String?,
      contentURL: json['contentURL'] as String?,
      openURL: json['openURL'] as String?,
      openTitle: json['openTitle'] as String?,
      illustration: json['illustration'] as String?,
      receiveWay: json['receiveWay'] as String?,
      isNotPro: json['isNotPro'] as bool? ?? true,
      startAt: _parseDate(json['startAt'] as String?),
      endAt: _parseDate(json['endAt'] as String?),
      platforms:
          (json['platforms'] as List<dynamic>?)
              ?.map((item) => _parsePlatform(item as String))
              .toList() ??
          const [ActivityPlatform.ios],
      isNew: json['isNew'] as bool? ?? false,
    );
  }

  final int id;
  final String emoji;
  final String title;
  final String languageCode;
  final String? content;
  final String? contentURL;
  final String? openURL;
  final String? openTitle;
  final String? illustration;
  final String? receiveWay;
  final bool isNotPro;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<ActivityPlatform> platforms;
  final bool isNew;

  bool isAvailable(ActivityPlatform platform) {
    return platforms.contains(platform);
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static ActivityPlatform _parsePlatform(String value) {
    return switch (value) {
      'android' => ActivityPlatform.android,
      _ => ActivityPlatform.ios,
    };
  }
}

class AppActivityRepository {
  AppActivityRepository({
    required this.appStoreRepository,
    required SharedPreferences sp,
  }) : _sp = sp;

  final SharedPreferences _sp;
  final AppStoreRepository appStoreRepository;

  final _controller = StreamController<List<ActivityMessageEntity>>();
  Stream<List<ActivityMessageEntity>> get onActivityChange =>
      _controller.stream;

  static const kActivityNotShowAgain = 'activity_not_show_again';
  static const kActivityWillShowAt = 'activity_will_show_at';

  static const _activityItemsAsset = 'assets/files/activity_messages.json';

  Future<List<ActivityMessageEntity>> _loadItems() async {
    final rawJson = await rootBundle.loadString(_activityItemsAsset);
    final decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              ActivityMessageEntity.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  List<String> get _languageCodes {
    final locale = PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode;
    final scriptCode = locale.scriptCode;
    if (scriptCode == null || scriptCode.isEmpty) {
      return [languageCode];
    }
    return ['${languageCode}_$scriptCode', languageCode];
  }

  bool _matchesLanguage(ActivityMessageEntity item) {
    return _languageCodes.contains(item.languageCode);
  }

  Future<bool> isReleaseVersion() async {
    return appStoreRepository.isReleaseVersion();
  }

  Future<List<ActivityMessageEntity>> fetch({bool isNew = false}) async {
    // if (!await isReleaseVersion()) return [];

    final isPremium = await AppPurchases.instance.isPremium;
    final items = await _loadItems();

    final now = DateTime.now();
    final activities = items.where((item) {
      if (!_matchesLanguage(item)) return false;
      if (item.isNotPro == isPremium) return false;

      if (item.startAt != null && now.isBefore(item.startAt!)) return false;
      if (item.endAt != null && now.isAfter(item.endAt!)) return false;

      if (item.platforms.isEmpty) return false;
      if (Platform.isIOS && !item.platforms.contains(ActivityPlatform.ios)) {
        return false;
      }
      if (Platform.isAndroid &&
          !item.platforms.contains(ActivityPlatform.android)) {
        return false;
      }

      if (isNew && !item.isNew) return false;

      final notShowAgain = _sp.getBool('${kActivityNotShowAgain}_${item.id}');
      if (notShowAgain != null && notShowAgain) return false;

      final willShowAt = _sp.getInt('${kActivityWillShowAt}_${item.id}');
      if (willShowAt != null &&
          now.isAfter(DateTime.fromMillisecondsSinceEpoch(willShowAt))) {
        return false;
      }

      return true;
    }).toList();
    _controller.add(activities);
    return activities;
  }

  Future<List<ActivityMessageEntity>> fetchAll() async {
    // if (!await isReleaseVersion()) return [];

    final isPremium = await AppPurchases.instance.isPremium;
    final items = await _loadItems();

    final now = DateTime.now();
    return items.where((item) {
      if (!_matchesLanguage(item)) return false;
      if (item.isNotPro == isPremium) return false;

      if (item.startAt != null && now.isBefore(item.startAt!)) return false;
      if (item.endAt != null && now.isAfter(item.endAt!)) return false;

      if (item.platforms.isEmpty) return false;
      if (Platform.isIOS && !item.platforms.contains(ActivityPlatform.ios)) {
        return false;
      }
      if (Platform.isAndroid &&
          !item.platforms.contains(ActivityPlatform.android)) {
        return false;
      }

      if (kDebugMode) {
        _sp
          ..remove('${kActivityNotShowAgain}_${item.id}')
          ..remove('${kActivityWillShowAt}_${item.id}');
      }
      return true;
    }).toList();
  }

  void notShowAgain(ActivityMessageEntity message) {
    _sp.setBool('${kActivityNotShowAgain}_${message.id}', true);
  }

  void willShow(ActivityMessageEntity message, DateTime? date) {
    if (date == null) {
      _sp.remove('${kActivityWillShowAt}_${message.id}');
    } else {
      _sp.setInt(
        '${kActivityWillShowAt}_${message.id}',
        date.millisecondsSinceEpoch,
      );
    }
  }
}
