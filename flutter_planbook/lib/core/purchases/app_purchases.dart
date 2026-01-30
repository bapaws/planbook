import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/core/purchases/alipay_purchases.dart';
import 'package:flutter_planbook/core/purchases/app_purchases_interface.dart';
import 'package:flutter_planbook/core/purchases/revenue_cat_purchases.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';

class AppPurchases implements AppPurchasesInterface {
  AppPurchases({
    required bool isAlipayEnabled,
    required AppPurchasesInterface alipayPurchases,
    required AppPurchasesInterface revenueCatPurchases,
  }) : _alipayPurchases = alipayPurchases,
       _revenueCatPurchases = revenueCatPurchases,
       _isAlipayEnabled = isAlipayEnabled;

  final bool _isAlipayEnabled;
  final AppPurchasesInterface _alipayPurchases;
  final AppPurchasesInterface _revenueCatPurchases;

  bool get isAndroidChina =>
      kDebugMode || (Platform.isAndroid && _isAlipayEnabled);

  static late final AppPurchases instance;

  static Future<void> initialize({bool enableAlipay = false}) async {
    instance = AppPurchases(
      isAlipayEnabled: enableAlipay,
      alipayPurchases: const AlipayPurchases(),
      revenueCatPurchases: const RevenueCatPurchases(),
    );
  }

  Future<bool> get isPremium async {
    final activeProductIdentifier = await getActiveIdentifier();
    return activeProductIdentifier != null;
  }

  @override
  Future<String?> purchase(StoreProduct storeProduct) async {
    try {
      if (isAndroidChina) {
        return await _alipayPurchases.purchase(storeProduct);
      } else {
        return await _revenueCatPurchases.purchase(storeProduct);
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('purchase error: $e');
      }
    }
    return null;
  }

  @override
  Future<String?> restore() async {
    try {
      final result = await _revenueCatPurchases.restore();
      if (result != null) return result;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('restore error: $e');
      }
    }
    return _alipayPurchases.restore();
  }

  @override
  Future<String?> getActiveIdentifier() async {
    try {
      final result = await _revenueCatPurchases.getActiveIdentifier();
      if (result != null) return result;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('getActiveProductIdentifier error: $e');
      }
    }

    return _alipayPurchases.getActiveIdentifier();
  }

  @override
  Future<List<StoreProduct>> getStoreProducts() async {
    try {
      if (isAndroidChina) {
        return await _alipayPurchases.getStoreProducts();
      } else {
        return await _revenueCatPurchases.getStoreProducts();
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('getStoreProducts error: $e');
      }
    }
    return [];
  }

  @override
  Future<String?> getAppUserID() async {
    try {
      final result = await _revenueCatPurchases.getAppUserID();
      if (result != null) return result;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('getAppUserID error: $e');
      }
    }
    return _alipayPurchases.getAppUserID();
  }

  @override
  Future<String?> logIn(String appUserID) async {
    try {
      final result = await _revenueCatPurchases.logIn(appUserID);
      if (result != null) return result;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('logIn error: $e');
      }
    }
    return _alipayPurchases.logIn(appUserID);
  }
}
