import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/core/purchases/alipay_purchases.dart';
import 'package:flutter_planbook/core/purchases/app_purchases_interface.dart';
import 'package:flutter_planbook/core/purchases/revenue_cat_purchases.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';
import 'package:flutter_planbook/core/purchases/wechat_purchases.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/users/users_repository.dart';

/// 国内支付方式（仅 [PurchaseChannel.chinaPay] 下有效）
enum ChinaPayMethod { alipay, wechat }

/// 安装包对应的「购买」通道（初始化时定死，运行期不变）
enum PurchaseChannel {
  /// App Store / Google Play → RevenueCat
  store,

  /// 国内市场 → 支付宝或微信
  chinaPay,
}

/// 门面：购买走单一通道；会员判定 / restore 按优先级合并多数据源。
class AppPurchases implements AppPurchasesInterface {
  AppPurchases({
    required this.channel,
    required bool revenueCatAvailable,
    required AppPurchasesInterface alipayPurchases,
    required AppPurchasesInterface wechatPurchases,
    required AppPurchasesInterface revenueCatPurchases,
  }) : _revenueCatAvailable = revenueCatAvailable,
       _alipay = alipayPurchases,
       _wechat = wechatPurchases,
       _revenueCat = revenueCatPurchases;

  final PurchaseChannel channel;
  final bool _revenueCatAvailable;
  final AppPurchasesInterface _alipay;
  final AppPurchasesInterface _wechat;
  final AppPurchasesInterface _revenueCat;

  static late final AppPurchases instance;

  /// UI：是否国内支付包（支付宝/微信入口、协议等）
  bool get usesChinaPay => channel == PurchaseChannel.chinaPay;

  /// 兼容旧调用：Android/鸿蒙 + 国内支付包
  bool get isAndroidChina => (Platform.isAndroid || kIsOhos) && usesChinaPay;

  /// 拉商品列表的后端（国内包两渠道共用同一商品表，默认走支付宝）
  AppPurchasesInterface get _productBackend {
    if (channel == PurchaseChannel.chinaPay) return _alipay;
    return _revenueCat;
  }

  /// 实际发起购买的后端；国内包由调用方显式指定支付方式，
  /// 不能用全局可变字段（并发点击会串渠道导致重复扣款）
  AppPurchasesInterface _purchaseBackend(ChinaPayMethod? chinaPayMethod) {
    if (channel == PurchaseChannel.chinaPay) {
      return chinaPayMethod == ChinaPayMethod.wechat ? _wechat : _alipay;
    }
    return _revenueCat;
  }

  /// 会员判定与 restore 的数据源（有值即返回，按优先级）
  ///
  /// - 国内：entitlements →（可选）RC 云端历史订阅
  /// - 海外：RC → entitlements（国内买过）
  List<AppPurchasesInterface> get _entitlementSources {
    switch (channel) {
      case PurchaseChannel.chinaPay:
        return [
          _alipay,
          if (_revenueCatAvailable) _revenueCat,
        ];
      case PurchaseChannel.store:
        return [
          if (_revenueCatAvailable) _revenueCat,
          _alipay,
        ];
    }
  }

  static Future<void> initialize({bool enableChinaPay = false}) async {
    if (!kIsOhos) await RevenueCatPurchases.configure();
    final revenueCatAvailable =
        !kIsWeb && !kIsOhos && (Platform.isAndroid || Platform.isIOS);
    instance = AppPurchases(
      channel: enableChinaPay
          ? PurchaseChannel.chinaPay
          : PurchaseChannel.store,
      revenueCatAvailable: revenueCatAvailable,
      alipayPurchases: AlipayPurchases(),
      wechatPurchases: WechatPurchases(),
      revenueCatPurchases: const RevenueCatPurchases(),
    );
  }

  Future<bool> get isPremium async {
    return await getActiveIdentifier() != null;
  }

  @override
  Future<String?> purchase(
    StoreProduct storeProduct, {
    ChinaPayMethod? chinaPayMethod,
  }) async {
    try {
      return await _purchaseBackend(chinaPayMethod).purchase(storeProduct);
    } on Object catch (e) {
      // 含 StateError 等 Error：避免冒泡导致 BLoC 停在 loading
      if (kDebugMode) print('purchase error: $e');
      return null;
    }
  }

  @override
  Future<List<StoreProduct>> getStoreProducts() async {
    try {
      return await _productBackend.getStoreProducts();
    } on Exception catch (e) {
      if (kDebugMode) print('getStoreProducts error: $e');
      return [];
    }
  }

  @override
  Future<String?> getActiveIdentifier() async {
    switch (channel) {
      case PurchaseChannel.chinaPay:
        return _firstActive(
          _entitlementSources,
          (s) => s.getActiveIdentifier(),
        );
      case PurchaseChannel.store:
        // 海外：先 RC；再 fallback 服务端 entitlements（含 revenuecat）。
        // 不能排除 revenuecat：webhook 已写入而 SDK 未同步时，
        // 排除会导致已付费用户（设置页能看到到期日）无法点亮 PRO。
        if (_revenueCatAvailable) {
          try {
            final rc = await _revenueCat.getActiveIdentifier();
            if (rc != null) return rc;
            return UsersRepository.instance.getActiveEntitlementProductId();
          } on Exception catch (e) {
            if (kDebugMode) print('getActiveIdentifier RC error: $e');
            return UsersRepository.instance.getActiveEntitlementProductId();
          }
        }
        return UsersRepository.instance.getActiveEntitlementProductId();
    }
  }

  @override
  Future<String?> restore() async {
    // 国内补单：支付宝 + 微信都要试；RC 在 entitlementSources 里已含
    final sources = <AppPurchasesInterface>[
      ..._entitlementSources,
      if (channel == PurchaseChannel.chinaPay) _wechat,
    ];
    // 去重（国内 _alipay 已在 sources 中）
    final seen = <AppPurchasesInterface>{};
    final unique = <AppPurchasesInterface>[];
    for (final s in sources) {
      if (seen.add(s)) unique.add(s);
    }
    final restored = await _firstActive(unique, (s) => s.restore());
    if (restored != null) return restored;
    // 无待同步订单时仍返回当前有效会员（若有）
    return getActiveIdentifier();
  }

  @override
  Future<String?> getAppUserID() async {
    return _firstActive(
      [
        if (_revenueCatAvailable) _revenueCat,
        _alipay,
      ],
      (s) => s.getAppUserID(),
    );
  }

  @override
  Future<String?> logIn(String appUserID) async {
    // RC 必须绑定 UID（webhook）；再刷新本地 entitlements
    if (_revenueCatAvailable) {
      try {
        await _revenueCat.logIn(appUserID);
      } on Exception catch (e) {
        if (kDebugMode) print('logIn RC error: $e');
      }
    }
    return getActiveIdentifier();
  }

  static Future<String?> _firstActive(
    List<AppPurchasesInterface> sources,
    Future<String?> Function(AppPurchasesInterface source) action,
  ) async {
    for (final source in sources) {
      try {
        final result = await action(source);
        if (result != null) return result;
      } on Exception catch (e) {
        if (kDebugMode) print('purchases source error: $e');
      }
    }
    return null;
  }
}
