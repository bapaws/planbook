import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// {
//  "resultCount":1,
//  "results": [
// {"screenshotUrls":[], "ipadScreenshotUrls":[], "appletvScreenshotUrls":[],
// "artworkUrl512":"https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/de/11/87/de118747-b2c0-6392-103c-268beda7f04f/AppIcon-0-1x_U007epad-0-1-85-220-0.png/512x512bb.jpg", "artistViewUrl":"https://apps.apple.com/cn/developer/%E7%AD%B1%E5%BD%A4-%E4%BD%99/id1622372136?uo=4",
// "artworkUrl60":"https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/de/11/87/de118747-b2c0-6392-103c-268beda7f04f/AppIcon-0-1x_U007epad-0-1-85-220-0.png/60x60bb.jpg",
// "artworkUrl100":"https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/de/11/87/de118747-b2c0-6392-103c-268beda7f04f/AppIcon-0-1x_U007epad-0-1-85-220-0.png/100x100bb.jpg", "features":["iosUniversal"],
// "supportedDevices":["iPhone5s-iPhone5s", "iPadAir-iPadAir", "iPadAirCellular-iPadAirCellular", "iPadMiniRetina-iPadMiniRetina", "iPadMiniRetinaCellular-iPadMiniRetinaCellular", "iPhone6-iPhone6", "iPhone6Plus-iPhone6Plus", "iPadAir2-iPadAir2", "iPadAir2Cellular-iPadAir2Cellular", "iPadMini3-iPadMini3", "iPadMini3Cellular-iPadMini3Cellular", "iPodTouchSixthGen-iPodTouchSixthGen", "iPhone6s-iPhone6s", "iPhone6sPlus-iPhone6sPlus", "iPadMini4-iPadMini4", "iPadMini4Cellular-iPadMini4Cellular", "iPadPro-iPadPro", "iPadProCellular-iPadProCellular", "iPadPro97-iPadPro97", "iPadPro97Cellular-iPadPro97Cellular", "iPhoneSE-iPhoneSE", "iPhone7-iPhone7", "iPhone7Plus-iPhone7Plus", "iPad611-iPad611", "iPad612-iPad612", "iPad71-iPad71", "iPad72-iPad72", "iPad73-iPad73", "iPad74-iPad74", "iPhone8-iPhone8", "iPhone8Plus-iPhone8Plus", "iPhoneX-iPhoneX", "iPad75-iPad75", "iPad76-iPad76", "iPhoneXS-iPhoneXS", "iPhoneXSMax-iPhoneXSMax", "iPhoneXR-iPhoneXR", "iPad812-iPad812", "iPad834-iPad834", "iPad856-iPad856", "iPad878-iPad878", "iPadMini5-iPadMini5", "iPadMini5Cellular-iPadMini5Cellular", "iPadAir3-iPadAir3", "iPadAir3Cellular-iPadAir3Cellular", "iPodTouchSeventhGen-iPodTouchSeventhGen", "iPhone11-iPhone11", "iPhone11Pro-iPhone11Pro", "iPadSeventhGen-iPadSeventhGen", "iPadSeventhGenCellular-iPadSeventhGenCellular", "iPhone11ProMax-iPhone11ProMax", "iPhoneSESecondGen-iPhoneSESecondGen", "iPadProSecondGen-iPadProSecondGen", "iPadProSecondGenCellular-iPadProSecondGenCellular", "iPadProFourthGen-iPadProFourthGen", "iPadProFourthGenCellular-iPadProFourthGenCellular", "iPhone12Mini-iPhone12Mini", "iPhone12-iPhone12", "iPhone12Pro-iPhone12Pro", "iPhone12ProMax-iPhone12ProMax", "iPadAir4-iPadAir4", "iPadAir4Cellular-iPadAir4Cellular", "iPadEighthGen-iPadEighthGen", "iPadEighthGenCellular-iPadEighthGenCellular", "iPadProThirdGen-iPadProThirdGen", "iPadProThirdGenCellular-iPadProThirdGenCellular", "iPadProFifthGen-iPadProFifthGen", "iPadProFifthGenCellular-iPadProFifthGenCellular", "iPhone13Pro-iPhone13Pro", "iPhone13ProMax-iPhone13ProMax", "iPhone13Mini-iPhone13Mini", "iPhone13-iPhone13", "iPadMiniSixthGen-iPadMiniSixthGen", "iPadMiniSixthGenCellular-iPadMiniSixthGenCellular", "iPadNinthGen-iPadNinthGen", "iPadNinthGenCellular-iPadNinthGenCellular", "iPhoneSEThirdGen-iPhoneSEThirdGen", "iPadAirFifthGen-iPadAirFifthGen", "iPadAirFifthGenCellular-iPadAirFifthGenCellular", "iPhone14-iPhone14", "iPhone14Plus-iPhone14Plus", "iPhone14Pro-iPhone14Pro", "iPhone14ProMax-iPhone14ProMax", "iPadTenthGen-iPadTenthGen", "iPadTenthGenCellular-iPadTenthGenCellular", "iPadPro11FourthGen-iPadPro11FourthGen", "iPadPro11FourthGenCellular-iPadPro11FourthGenCellular", "iPadProSixthGen-iPadProSixthGen", "iPadProSixthGenCellular-iPadProSixthGenCellular", "iPhone15-iPhone15", "iPhone15Plus-iPhone15Plus", "iPhone15Pro-iPhone15Pro", "iPhone15ProMax-iPhone15ProMax", "iPadAir11M2-iPadAir11M2", "iPadAir11M2Cellular-iPadAir11M2Cellular", "iPadAir13M2-iPadAir13M2", "iPadAir13M2Cellular-iPadAir13M2Cellular", "iPadPro11M4-iPadPro11M4", "iPadPro11M4Cellular-iPadPro11M4Cellular", "iPadPro13M4-iPadPro13M4", "iPadPro13M4Cellular-iPadPro13M4Cellular", "iPhone16-iPhone16", "iPhone16Plus-iPhone16Plus", "iPhone16Pro-iPhone16Pro", "iPhone16ProMax-iPhone16ProMax", "iPadMiniA17Pro-iPadMiniA17Pro", "iPadMiniA17ProCellular-iPadMiniA17ProCellular", "iPhone16e-iPhone16e", "iPadA16-iPadA16", "iPadA16Cellular-iPadA16Cellular", "iPadAir11M3-iPadAir11M3", "iPadAir11M3Cellular-iPadAir11M3Cellular", "iPadAir13M3-iPadAir13M3", "iPadAir13M3Cellular-iPadAir13M3Cellular"], "advisories":[], "isGameCenterEnabled":false, "kind":"software", "averageUserRatingForCurrentVersion":4.79999999999999982236431605997495353221893310546875, "minimumOsVersion":"13.0", "languageCodesISO2A":["EN", "ZH", "ES"], "fileSizeBytes":"128829440", "formattedPrice":"免费", "userRatingCountForCurrentVersion":25, "trackContentRating":"4+", "sellerUrl":"https://privacy.bapaws.com", "trackCensoredName":"Yummy - 宝宝辅食日记&膳食指南", "trackViewUrl":"https://apps.apple.com/cn/app/yummy-%E5%AE%9D%E5%AE%9D%E8%BE%85%E9%A3%9F%E6%97%A5%E8%AE%B0-%E8%86%B3%E9%A3%9F%E6%8C%87%E5%8D%97/id6717578882?uo=4", "contentAdvisoryRating":"4+", "averageUserRating":4.79999999999999982236431605997495353221893310546875, "artistId":1622372136, "artistName":"筱彤 余", "genres":["美食佳饮", "生活"], "price":0.00, "bundleId":"com.bapaws.yummy", "releaseDate":"2024-11-14T08:00:00Z", "trackId":6717578882, "trackName":"Yummy - 宝宝辅食日记&膳食指南", "genreIds":["6023", "6012"], "primaryGenreName":"Food & Drink", "primaryGenreId":6023, "isVppDeviceBasedLicensingEnabled":true, "sellerName":"筱彤 余", "currentVersionReleaseDate":"2025-05-15T00:06:01Z", "releaseNotes":"本次更新：\n- 自定义食物\n- 辅食日历小组件\n- 辅食月视图\n- 修复一些已知问题", "version":"2.2.0", "wrapperType":"software", "currency":"CNY",
// "description":"给新手爸妈的宝宝辅食添加秘诀！\n现在就来体验超好用的宝宝辅食记录工具—— Yummy！\n\n做不好宝宝辅食管理？不清楚宝宝缺少哪些营养摄入？辅食记录、营养管理，这些都交给Yummy来解决吧！\n\n#营养圆环\n按照中国营养学会发布的婴幼儿平衡膳食宝塔来设计的营养圆环，请爸爸妈妈们认真记录下每顿辅食，为闭环而努力吧！\n#辅食记录\n轻点加号，就可以记录下此刻的宝宝都吃了些什么，还可以搭配自己拍的照片哦。\n通过时间轴可以一眼看到宝宝每日都吃了哪些食物，滑动日历还可以看到过去的记录。\n#食物库\n一眼就能看到超多营养丰富的食物，还有他们的营养分布。快来让宝宝尝试更多丰富的食物吧！\n#宝宝的喜好\n不仅仅只是记录辅食！还能轻松记录宝宝对辅食的反应，就可以了解宝宝喜欢合理添加食材啦！\n\n自动订阅服务：\n确认购买后，将向您的Apple账户收费，购买连续包月、包年项目，将自动续费，Apple账户会在到期前24小时内扣费，扣费成功后订阅周期顺延至下一个订阅周期;自动订阅如需取消，请在当前订阅周期结束前24小时前关闭自动续费功能，你可以在"设置"，点击"Apple ID"，选择"查看Apple ID"，点击"订阅"选择 Yummy 高级版取消订阅即可。若出现充值未到账的情况，请将您的Apple ID和扣款凭证邮件至dev@bapaws.com;\n\n隐私协议：https://lowly-centaur-2e4.notion.site/128ee0cfd97681be89eaf9bb7a2290bb\n服务协议：https://lowly-centaur-2e4.notion.site/128ee0cfd97681238130c76716b85bba\n \n如果您有任何建议，可以通过下面的邮箱联系到我们：\n邮箱：dev@bapaws.com", "userRatingCount":25}]
// }

class AppStoreResponse {
  AppStoreResponse({
    required this.resultCount,
    required this.results,
  });

  factory AppStoreResponse.fromJson(Map<String, dynamic> json) {
    return AppStoreResponse(
      resultCount: json['resultCount'] as int? ?? 0,
      results:
          (json['results'] as List?)
              ?.map((e) => AppStoreResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  final int resultCount;
  final List<AppStoreResult> results;
}

class AppStoreResult {
  AppStoreResult({
    this.version,
    this.trackName,
    this.bundleId,
    this.releaseDate,
    this.currentVersionReleaseDate,
    this.releaseNotes,
    this.averageUserRating,
    this.userRatingCount,
    this.formattedPrice,
    this.minimumOsVersion,
    this.languageCodesISO2A,
    this.genres,
    this.primaryGenreName,
    this.description,
    this.sellerName,
    this.artistName,
    this.trackViewUrl,
    this.artworkUrl512,
    this.artworkUrl100,
    this.artworkUrl60,
  });

  factory AppStoreResult.fromJson(Map<String, dynamic> json) {
    return AppStoreResult(
      version: _getString(json, 'version'),
      trackName: _getString(json, 'trackName'),
      bundleId: _getString(json, 'bundleId'),
      releaseDate: _getString(json, 'releaseDate'),
      currentVersionReleaseDate: _getString(json, 'currentVersionReleaseDate'),
      releaseNotes: _getString(json, 'releaseNotes'),
      averageUserRating: _getDouble(json, 'averageUserRating'),
      userRatingCount: _getInt(json, 'userRatingCount'),
      formattedPrice: _getString(json, 'formattedPrice'),
      minimumOsVersion: _getString(json, 'minimumOsVersion'),
      languageCodesISO2A: _getStringList(json, 'languageCodesISO2A'),
      genres: _getStringList(json, 'genres'),
      primaryGenreName: _getString(json, 'primaryGenreName'),
      description: _getString(json, 'description'),
      sellerName: _getString(json, 'sellerName'),
      artistName: _getString(json, 'artistName'),
      trackViewUrl: _getString(json, 'trackViewUrl'),
      artworkUrl512: _getString(json, 'artworkUrl512'),
      artworkUrl100: _getString(json, 'artworkUrl100'),
      artworkUrl60: _getString(json, 'artworkUrl60'),
    );
  }
  final String? version;
  final String? trackName;
  final String? bundleId;
  final String? releaseDate;
  final String? currentVersionReleaseDate;
  final String? releaseNotes;
  final double? averageUserRating;
  final int? userRatingCount;
  final String? formattedPrice;
  final String? minimumOsVersion;
  final List<String>? languageCodesISO2A;
  final List<String>? genres;
  final String? primaryGenreName;
  final String? description;
  final String? sellerName;
  final String? artistName;
  final String? trackViewUrl;
  final String? artworkUrl512;
  final String? artworkUrl100;
  final String? artworkUrl60;

  static String? _getString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    return value.toString();
  }

  static int? _getInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static double? _getDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  static List<String>? _getStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }
}

class AppStoreRepository {
  AppStoreRepository({required SharedPreferences sp}) : _sp = sp;

  final SharedPreferences _sp;

  static const kIsReleaseVersion = 'is_release_version';

  Future<bool> isReleaseVersion() async {
    if (kDebugMode) {
      return true;
    }

    final isReleaseVersion = _sp.getBool(kIsReleaseVersion) ?? false;
    if (isReleaseVersion) {
      return true;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final appStoreVersion = await fetchVersion();
      if (appStoreVersion == null || currentVersion != appStoreVersion) {
        return false;
      }

      await _sp.setBool(kIsReleaseVersion, true);
      return true;
    } catch (e) {
      log('版本检查失败: $e');
      return false;
    }
  }

  Future<String?> fetchVersion({
    String? bundleId = 'com.bapaws.yummy',
    String country = 'cn',
  }) async {
    try {
      final url = 'https://itunes.apple.com/$country/lookup?bundleId=$bundleId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return AppStoreResponse.fromJson(data).results.first.version;
      }
      return null;
    } catch (e) {
      log('获取 App Store 版本失败: $e');
      return null;
    }
  }

  Future<AppStoreResponse?> fetch({
    required String bundleId,
  }) async {
    try {
      final url = 'https://itunes.apple.com/cn/lookup?bundleId=$bundleId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return AppStoreResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      log('获取 App Store 版本失败: $e');
      return null;
    }
  }
}
