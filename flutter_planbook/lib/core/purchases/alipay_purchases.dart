import 'package:flutter_planbook/core/purchases/app_purchases_interface.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tobias/tobias.dart';

final class AlipayPurchases implements AppPurchasesInterface {
  const AlipayPurchases();
  SupabaseClient? get _supabase => AppSupabase.client;

  @override
  Future<String?> purchase(StoreProduct storeProduct) async {
    final response = await _supabase?.functions.invoke(
      'planbook-alipay-create-order',
      body: {
        'product_id': storeProduct.id.split(':').first,
      },
    );
    if (response == null ||
        response.status != 200 ||
        response.data is! Map<String, dynamic>) {
      return null;
    }
    final data = response.data as Map<String, dynamic>;
    if (data['success'] != true) {
      return null;
    }
    final orderString = data['order_string'] as String?;
    if (orderString == null) {
      return null;
    }
    final result = await Tobias().pay(orderString);
    if (result['resultStatus'] == '9000') {
      return restore();
    }
    return null;
  }

  @override
  Future<String?> restore() async {
    final response = await _supabase?.functions.invoke(
      'planbook-alipay-query',
    );
    if (response == null ||
        response.status != 200 ||
        response.data is! Map<String, dynamic>) {
      return null;
    }
    final data = response.data as Map<String, dynamic>;
    if (data['success'] != true) {
      return null;
    }
    final userProfile = await UsersRepository.instance.getUserProfile(
      force: true,
    );
    if (userProfile == null) {
      return null;
    }
    return userProfile.productId;
  }

  @override
  Future<String?> getActiveIdentifier() async {
    final userProfile = await UsersRepository.instance.getUserProfile();
    if (userProfile == null) {
      return null;
    }
    final productId = userProfile.productId;
    if (productId == null) return null;
    if (productId.toLowerCase().contains('lifetime')) return productId;
    final expiresAt = userProfile.expiresAt;
    if (expiresAt == null) return null;
    if (expiresAt.isBefore(DateTime.now())) return null;
    return productId;
  }

  @override
  Future<List<StoreProduct>> getStoreProducts() async {
    final response = await _supabase
        ?.from('store_products')
        .select()
        .eq('is_enabled', true)
        .isFilter('deleted_at', null)
        .order('order', ascending: true);
    return response?.map(StoreProduct.fromJson).toList() ?? [];
  }

  @override
  Future<String?> getAppUserID() async {
    return _supabase?.auth.currentUser?.id;
  }

  @override
  Future<String?> logIn(String appUserID) async {
    return getActiveIdentifier();
  }
}
