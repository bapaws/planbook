import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

extension PackageX on Package {
  bool isAnnual() =>
      identifier.toLowerCase().contains('yearly') ||
      identifier.toLowerCase().contains('annual');
}

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

class AppPurchases {
  AppPurchases._() {
    /// 初始化直接获取
    Purchases.getCustomerInfo().then((info) {
      _customerInfoStreamController.add(info);
    });

    /// 监听变化
    Purchases.addCustomerInfoUpdateListener((info) {
      _customerInfoStreamController.add(info);
    });
  }

  static final AppPurchases instance = AppPurchases._();

  Future<bool> get isPremium async {
    if (kDebugMode) {
      return false;
    }
    final info = await Purchases.getCustomerInfo();
    return info.activeProductIdentifier != null;
  }

  Future<bool> get isLifetime async {
    if (kDebugMode) {
      return true;
    }
    final info = await Purchases.getCustomerInfo();
    return info.activeProductIdentifier?.toLowerCase().contains('lifetime') ??
        false;
  }

  late final _customerInfoStreamController =
      StreamController<CustomerInfo?>.broadcast();

  Stream<CustomerInfo?> getCustomerInfo() {
    return _customerInfoStreamController.stream;
  }

  Future<String?> getActiveProductIdentifier() async {
    if (kDebugMode) {
      return 'lifetime';
    }

    final info = await Purchases.getCustomerInfo();
    return info.activeProductIdentifier;
  }

  Future<List<Package>?> getAvailablePackages() async {
    final offerings = await Purchases.getOfferings();
    final availablePackages = offerings.current?.availablePackages;
    return availablePackages;
  }

  Future<List<Package>?> getOriginalPackages() async {
    final offerings = await Purchases.getOfferings();
    final availablePackages = offerings.all['original']?.availablePackages;
    return availablePackages;
  }

  Future<LogInResult> logIn(String appUserID) async {
    return Purchases.logIn(appUserID);
  }

  Future<CustomerInfo> restore() async {
    return Purchases.restorePurchases();
  }

  Future<String> getAppUserID() async {
    return Purchases.appUserID;
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo;
  }
}
