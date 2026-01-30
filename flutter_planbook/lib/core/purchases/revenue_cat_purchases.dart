import 'package:collection/collection.dart';
import 'package:flutter_planbook/core/purchases/app_purchases_interface.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';
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

  @override
  Future<String?> purchase(StoreProduct storeProduct) async {
    final products = await Purchases.getProducts([storeProduct.id]);
    final product = products.firstWhere(
      (e) => e.identifier == storeProduct.id,
    );
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
