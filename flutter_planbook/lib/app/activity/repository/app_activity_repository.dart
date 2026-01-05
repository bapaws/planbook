import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/app/activity/repository/app_store_repository.dart';
import 'package:planbook_api/supabase/app_purchases.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });
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
}

class AppActivityRepository {
  AppActivityRepository({
    required AppStoreRepository appStoreRepository,
    required SharedPreferences sp,
  }) : _appStoreRepository = appStoreRepository,
       _sp = sp;

  final SharedPreferences _sp;
  final AppStoreRepository _appStoreRepository;

  final _controller = StreamController<List<ActivityMessageEntity>>();
  Stream<List<ActivityMessageEntity>> get onActivityChange =>
      _controller.stream;

  static const kActivityNotShowAgain = 'activity_not_show_again';
  static const kActivityWillShowAt = 'activity_will_show_at';

  final List<ActivityMessageEntity> _items = [
    ActivityMessageEntity(
      id: 0,
      emoji: '🎁',
      title: '快来领取包月会员',
      languageCode: 'zh',
      content: '''
**App Store 五🌟好评，可免费领取包月会员～**
1. 点击「[**计划本**](https://apps.apple.com/app/id6737596725?action=write-review)」，打开 App Store。
2. 给「[**计划本**](https://apps.apple.com/app/id6737596725?action=write-review)」一个五🌟好评，也可以同时写下使用体验。
''',
      contentURL: 'https://bapaws.super.site/活动消息/免费领取月费会员',
      openURL: 'https://apps.apple.com/app/id6737596725?action=write-review',
      openTitle: '去写评论',
      illustration: 'gift_box.svg',
      receiveWay: '''
🔴小红书
  1. 打开小红书，🔍搜索开发者小红书账户：[6481492100000000120342c4](xhsdiscover://user/6481492100000000120342c4)。点击❤️关注。
  2. 点击私信页面，将「**你的评分与评论**」页面的截图发送给账户。
  3. 我们将在 24 小时内，私信会员兑换码。\n\n
🟢微信
  1. 添加「**计划本**」客服账户：[**Bapaws**](weixin://)。
  2. 将「**你的评分与评论**」页面的截图发送给客服账户。
  3. 将在 24 小时内，发送会员兑换码。
**👉由于会员码的限制，只能在 App Store 兑换一次。**
''',
      endAt: DateTime(2025, 12, 31),
    ),
    const ActivityMessageEntity(
      id: 2,
      emoji: '💎',
      title: '发小红书，免费领会员',
      languageCode: 'zh',
      content: '''
| 活动奖励 | 活动要求 |
|----------|--------|
| 月会员   | 五🌟好评   |
| 年会员   | 五🌟好评 + 4 篇笔记 |

*💡注意：由于兑换码限制，月会员和年会员活动，只能选择其中一种参与，不能同时参与。*

## 第❶步：App Store 评价

1. 点击「[**计划本**](https://apps.apple.com/app/id6737596725?action=write-review)」，打开 App Store。
2. 给「[**计划本**](https://apps.apple.com/app/id6737596725?action=write-review)」一个五🌟好评，也可以同时写下使用体验。

如果只参加月会员活动，请按照领取方式，将「**你的评分与评论**」页面的截图发送给「**计划本**」客服账户：[**Bapaws**](weixin://) 或 [**MC Studio**](xhsdiscover://user/6481492100000000120342c4)。
我们将在 24 小时内，发送会员兑换码。


## 第❷步：[小红书](xhsdiscover://post/) 发“截图或录屏”笔记

### *发布频率*

一天 1 篇，无需连续可以间隔。

### *笔记内容*
您可以发布各种关于「**计划本**」的笔记，包括但不限于以下的主题：

  + 使用心得
  + 喜欢或经常使用的功能
  + 一天的任务
  + 等等…

每篇笔记不要使用相同的截图或录屏，可用四象限或任务列表、任务周视图、任务月视图、笔记时间轴页、手账页等。
可以在截图或录屏期间，摸索一下功能。

带上话题 **#计划本** **#计划本app**

### *参考截图*
![screenshots](assets/images/screenshots.png)

### *⚠️注意：*
  - ❌**二次编辑笔记无效，因为无法确认笔记时间**
  - ❌禁止出现送会员、集赞、互踩、二维码、链接、容易平台限流。笔记需公开且保留1个月以上，否则收回会员。

''',
      contentURL: 'https://bapaws.super.site/活动消息/发小红书赢年会员',
      openURL: 'xhsdiscover://user/6481492100000000120342c4',
      openTitle: '打开小红书',
      receiveWay: '''
### 🔴小红书
  1. 打开开发者小红书账户：[**MC Studio**](xhsdiscover://user/6481492100000000120342c4)。点击❤️关注。
  2. 点击私信页面，将您的笔记分享给账户。
  3. 我们将在 24 小时内，私信会员兑换码。

### 🟢微信
  1. 微信添加「**计划本**」客服账户：[**Bapaws**](weixin://)。
  2. 将您的笔记分享给客服的微信账户。
  3. 将在 24 小时内，发送会员兑换码。
**👉由于会员码的限制，只能在 App Store 兑换一次。**
''',
    ),
  ];

  String get _languageCode {
    return PlatformDispatcher.instance.locale.languageCode;
  }

  Future<bool> isReleaseVersion() async {
    return _appStoreRepository.isReleaseVersion();
  }

  Future<List<ActivityMessageEntity>> fetch() async {
    if (!await isReleaseVersion()) return [];

    final isPremium = await AppPurchases.instance.isPremium;

    final now = DateTime.now();
    final activities = _items.where((item) {
      if (item.languageCode != _languageCode) return false;
      if (item.isNotPro == isPremium) return false;

      if (item.startAt != null && now.isBefore(item.startAt!)) return false;
      if (item.endAt != null && now.isAfter(item.endAt!)) return false;

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
    if (!await isReleaseVersion()) return [];

    final isPremium = await AppPurchases.instance.isPremium;

    final now = DateTime.now();
    return _items.where((item) {
      if (item.languageCode != _languageCode) return false;
      if (item.isNotPro == isPremium) return false;

      if (item.startAt != null && now.isBefore(item.startAt!)) return false;
      if (item.endAt != null && now.isAfter(item.endAt!)) return false;

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
