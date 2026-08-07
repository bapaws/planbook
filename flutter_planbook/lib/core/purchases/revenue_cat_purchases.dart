import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_planbook/core/purchases/app_purchases_interface.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart' hide StoreProduct;

extension CustomerInfoX on CustomerInfo {
  String? get activeProductIdentifier {
    final values = entitlements.active.values;
    if (values.isEmpty) return null;
    final lifetime = values.firstWhereOrNull(
      (e) => e.productIdentifier.toLowerCase().contains('lifetime'),
    );
    if (lifetime != null) return lifetime.productIdentifier;

    final yearly = values.firstWhereOrNull(
      (e) =>
          e.productIdentifier.toLowerCase().contains('yearly') ||
          e.productIdentifier.toLowerCase().contains('annual'),
    );
    if (yearly != null) return yearly.productIdentifier;

    final monthly = values.firstWhereOrNull(
      (e) => e.productIdentifier.toLowerCase().contains('monthly'),
    );
    if (monthly != null) return monthly.productIdentifier;

    return null;
  }
}

final class RevenueCatPurchases implements AppPurchasesInterface {
  const RevenueCatPurchases();

  /// 配置 RevenueCat SDK
  static Future<void> configure() async {
    await Purchases.setProxyURL('https://api.rc-backup.com/');
    await Purchases.setLogLevel(LogLevel.error);

    /// Development use same id
    late final PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(
        'goog_jlxqPffDOplzoFISIizzxwRdFFk',
      );
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(
        'appl_aNYCwAWkYYxFFPdqMBTWIXzIzko',
      )..userDefaultsSuiteName = kAppGroupId;
    } else {
      throw UnimplementedError();
    }

    await Purchases.configure(configuration);
  }

  @override
  Future<String?> purchase(StoreProduct storeProduct) async {
    // 永久会员是一次性商品（无 subscriptionPeriod），默认只查订阅会返回空列表
    final productCategory = storeProduct.subscriptionPeriod == null
        ? ProductCategory.nonSubscription
        : ProductCategory.subscription;

    final products = await Purchases.getProducts(
      [storeProduct.id],
      productCategory: productCategory,
    );
    final product = products.firstWhereOrNull(
      (e) => e.identifier == storeProduct.id,
    );
    if (product == null) return null;

    final result = await Purchases.purchase(
      PurchaseParams.storeProduct(product),
    );
    return result.customerInfo.activeProductIdentifier;
  }

  @override
  Future<String?> restore() async {
    final info = await Purchases.restorePurchases();
    return info.activeProductIdentifier;
  }

  @override
  Future<String?> getActiveIdentifier() async {
    final info = await Purchases.getCustomerInfo();
    return info.activeProductIdentifier;
  }

  @override
  Future<List<StoreProduct>> getStoreProducts() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages
            .map(StoreProduct.fromRevenueCat)
            .toList() ??
        [];
  }

  @override
  Future<String?> getAppUserID() async {
    return Purchases.appUserID;
  }

  @override
  Future<String?> logIn(String appUserID) async {
    final info = await Purchases.logIn(appUserID);
    return info.customerInfo.activeProductIdentifier;
  }
}
