import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_planbook/app/activity/repository/app_store_repository.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:flutter_planbook/core/redeem/redeem_service.dart';
import 'package:redeem_client/redeem_client.dart';
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
    this.enableInAppRedeem = false,
    this.enableXhsClaim = false,
    this.xhsClaimURL,
    this.campaignId,
    this.fromRemote = false,
    this.requireImages = true,
    this.requireLink = false,
  });

  factory ActivityMessageEntity.fromJson(Map<String, dynamic> json) {
    final flags = proofFlags(
      requireImages: json['requireImages'] as bool?,
      requireLink: json['requireLink'] as bool?,
      enableXhsClaim: json['enableXhsClaim'] as bool? ?? false,
      enableInAppRedeem: json['enableInAppRedeem'] as bool? ?? false,
    );
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
      enableInAppRedeem: json['enableInAppRedeem'] as bool? ?? false,
      enableXhsClaim: json['enableXhsClaim'] as bool? ?? false,
      xhsClaimURL: json['xhsClaimURL'] as String?,
      requireImages: flags.images,
      requireLink: flags.link,
    );
  }

  static ({bool images, bool link}) proofFlags({
    bool? requireImages,
    bool? requireLink,
    bool enableXhsClaim = false,
    bool enableInAppRedeem = false,
  }) {
    if (requireImages == null && requireLink == null) {
      final xhsOnly = enableXhsClaim && !enableInAppRedeem;
      return (images: !xhsOnly, link: xhsOnly);
    }
    var images = requireImages ?? false;
    final link = requireLink ?? false;
    if (!images && !link) {
      images = true;
    }
    return (images: images, link: link);
  }

  static const kDefaultXhsClaimURL =
      'xhsdiscover://user/6481492100000000120342c4';

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
  final bool enableInAppRedeem;
  final bool enableXhsClaim;
  final String? xhsClaimURL;

  /// Redeem 活动 id；本地 json 没有此字段。
  final String? campaignId;

  /// 已由服务端按语言裁好，不再做 languageCode 过滤。
  final bool fromRemote;

  /// 提交时是否必须上传截图。
  final bool requireImages;

  /// 提交时是否必须填写链接（如小红书笔记）。
  final bool requireLink;

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

  /// 应用内切换的语言；`null` 表示跟随系统。
  Locale? _localeOverride;

  final _controller = StreamController<List<ActivityMessageEntity>>();
  Stream<List<ActivityMessageEntity>> get onActivityChange =>
      _controller.stream;

  static const kActivityNotShowAgain = 'activity_not_show_again';
  static const kActivityWillShowAt = 'activity_will_show_at';

  static const _activityItemsAsset = 'assets/files/activity_messages.json';

  List<ActivityMessageEntity>? _cachedItems;
  String? _cachedKey;

  /// 更新活动筛选使用的语言，切换语言后需重新 [fetch]。
  void updateLocale(Locale? locale) {
    _localeOverride = locale;
    _cachedItems = null;
    _cachedKey = null;
  }

  Locale get _effectiveLocale =>
      _localeOverride ?? PlatformDispatcher.instance.locale;

  /// 按当前语言生成匹配优先级，例如 zh_Hant → [zh_Hant, zh]。
  static List<String> languageCodesFor(Locale locale) {
    final languageCode = locale.languageCode;
    final scriptCode = locale.scriptCode;
    final codes = <String>[];
    if (scriptCode != null && scriptCode.isNotEmpty) {
      codes.add('${languageCode}_$scriptCode');
    }
    if (!codes.contains(languageCode)) {
      codes.add(languageCode);
    }
    return codes;
  }

  List<String> get _languageCodes => languageCodesFor(_effectiveLocale);

  bool _matchesLanguage(ActivityMessageEntity item) {
    if (item.fromRemote) return true;
    return _languageCodes.contains(item.languageCode);
  }

  String get bootstrapLocale {
    final locale = _effectiveLocale;
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant' ? 'zh-Hant' : 'zh-Hans';
    }
    return locale.languageCode;
  }

  String? get _bootstrapPlatform =>
      kDebugMode ? null : (Platform.isAndroid ? 'android' : 'ios');

  Future<List<ActivityMessageEntity>> _loadItems() async {
    final key = '$bootstrapLocale|${_bootstrapPlatform ?? 'any'}';
    if (_cachedItems != null && _cachedKey == key) return _cachedItems!;

    final remote = await _loadRemoteItems();
    final items = remote ?? await _loadAssetItems();
    _cachedItems = items;
    _cachedKey = key;
    return items;
  }

  Future<List<ActivityMessageEntity>?> _loadRemoteItems() async {
    if (!await RedeemService.instance.isAvailable) return null;
    try {
      final boot = await RedeemService.instance.bootstrap(
        locale: bootstrapLocale,
        platform: _bootstrapPlatform,
      );
      return [for (final c in boot.campaigns) _fromCampaign(c)];
    } on Object {
      return null;
    }
  }

  Future<List<ActivityMessageEntity>> _loadAssetItems() async {
    final rawJson = await rootBundle.loadString(_activityItemsAsset);
    final decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              ActivityMessageEntity.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static ActivityMessageEntity _fromCampaign(CampaignInfo c) {
    final emoji = c.copy.emoji;
    var title = c.copy.title;
    if (emoji.isNotEmpty && title.startsWith(emoji)) {
      title = title.substring(emoji.length).trim();
    }
    final rawPlats = c.platforms.isNotEmpty
        ? c.platforms
        : (c.platform == 'any' || c.platform.isEmpty
            ? const ['ios', 'android']
            : [c.platform]);
    final openTitle =
        c.copy.openTitle.isNotEmpty ? c.copy.openTitle : c.copy.cta;
    return ActivityMessageEntity(
      id: c.legacyId != 0 ? c.legacyId : (c.id.hashCode & 0x7fffffff),
      campaignId: c.id,
      fromRemote: true,
      emoji: emoji.isEmpty ? '🎁' : emoji,
      title: title,
      languageCode: '',
      content: c.copy.content.isNotEmpty ? c.copy.content : c.copy.subtitle,
      contentURL: c.copy.contentUrl.isEmpty ? null : c.copy.contentUrl,
      openURL: c.copy.openUrl.isEmpty ? null : c.copy.openUrl,
      openTitle: openTitle.isEmpty ? null : openTitle,
      illustration: c.illustration.isEmpty ? null : c.illustration,
      receiveWay: c.copy.receiveWay.isEmpty ? null : c.copy.receiveWay,
      isNotPro: c.isNotPro,
      startAt: ActivityMessageEntity._parseDate(c.startsAt),
      endAt: ActivityMessageEntity._parseDate(c.endsAt),
      platforms: [
        for (final p in rawPlats) ActivityMessageEntity._parsePlatform(p),
      ],
      isNew: c.isNew,
      enableInAppRedeem: c.enableInAppRedeem,
      enableXhsClaim: c.enableXhsClaim,
      xhsClaimURL: c.xhsClaimUrl.isEmpty ? null : c.xhsClaimUrl,
      requireImages: c.requireImages,
      requireLink: c.requireLink,
    );
  }

  Future<bool> isReleaseVersion() async {
    return appStoreRepository.isReleaseVersion();
  }

  Future<List<ActivityMessageEntity>> fetch({bool isNew = false}) async {
    if (!await isReleaseVersion()) return [];

    final isPremium = await AppPurchases.instance.isPremium;
    final items = await _loadItems();

    final now = DateTime.now();
    final activities = items.where((item) {
      if (!_matchesLanguage(item)) return false;
      if (item.isNotPro == isPremium) return false;

      if (item.startAt != null && now.isBefore(item.startAt!)) return false;
      if (item.endAt != null && now.isAfter(item.endAt!)) return false;

      if (!kDebugMode) {
        if (item.platforms.isEmpty) return false;
        if (Platform.isIOS && !item.platforms.contains(ActivityPlatform.ios)) {
          return false;
        }
        if (Platform.isAndroid &&
            !item.platforms.contains(ActivityPlatform.android)) {
          return false;
        }
      }

      if (isNew && !item.isNew) return false;

      final notShowAgain = _sp.getBool('${kActivityNotShowAgain}_${item.id}');
      if (notShowAgain != null && notShowAgain) return false;

      final willShowAt = _sp.getInt('${kActivityWillShowAt}_${item.id}');
      if (willShowAt != null &&
          now.isBefore(DateTime.fromMillisecondsSinceEpoch(willShowAt))) {
        return false;
      }

      return true;
    }).toList();
    _controller.add(activities);
    return activities;
  }

  Future<List<ActivityMessageEntity>> fetchAll() async {
    if (!await isReleaseVersion()) return [];

    final isPremium = await AppPurchases.instance.isPremium;
    final items = await _loadItems();

    final now = DateTime.now();
    return items.where((item) {
      if (!_matchesLanguage(item)) return false;
      if (item.isNotPro == isPremium) return false;

      if (item.startAt != null && now.isBefore(item.startAt!)) return false;
      if (item.endAt != null && now.isAfter(item.endAt!)) return false;

      if (!kDebugMode) {
        if (item.platforms.isEmpty) return false;
        if (Platform.isIOS && !item.platforms.contains(ActivityPlatform.ios)) {
          return false;
        }
        if (Platform.isAndroid &&
            !item.platforms.contains(ActivityPlatform.android)) {
          return false;
        }
      }

      if (kDebugMode) {
        _sp
          ..remove('${kActivityNotShowAgain}_${item.id}')
          ..remove('${kActivityWillShowAt}_${item.id}');
      }
      return true;
    }).toList();
  }

  /// 当前语言下支持 App 内兑换的活动（忽略「不再显示」）。
  Future<ActivityMessageEntity?> findInAppRedeemActivity() async {
    final items = await fetchAll();
    for (final item in items) {
      if (item.enableInAppRedeem) return item;
    }
    return null;
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

  /// 清除活动本地偏好（不再显示、稍后提醒），用于 Debug 重测。
  Future<void> clearLocalActivityPreferences() async {
    const prefixNotShow = '${kActivityNotShowAgain}_';
    const prefixWillShow = '${kActivityWillShowAt}_';
    for (final key in _sp.getKeys()) {
      if (key.startsWith(prefixNotShow) || key.startsWith(prefixWillShow)) {
        await _sp.remove(key);
      }
    }
  }
}
