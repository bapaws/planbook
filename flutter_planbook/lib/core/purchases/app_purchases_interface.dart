import 'package:flutter_planbook/core/purchases/store_product.dart';

abstract class AppPurchasesInterface {
  Future<String?> purchase(StoreProduct storeProduct);
  Future<String?> restore();
  Future<String?> getActiveIdentifier();
  Future<List<StoreProduct>> getStoreProducts();
  Future<String?> getAppUserID();
  Future<String?> logIn(String appUserID);
}
