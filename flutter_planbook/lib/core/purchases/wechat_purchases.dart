import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/core/purchases/app_purchases_interface.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';
import 'package:fluwx/fluwx.dart';
import 'package:planbook_repository/users/users_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 国内：微信支付（APP）+ 服务端验单。
final class WechatPurchases implements AppPurchasesInterface {
  WechatPurchases();

  final _fluwx = Fluwx();
  List<StoreProduct>? _cachedStoreProducts;

  SupabaseClient? get _supabase => Supabase.instance.client;

  @override
  Future<String?> purchase(StoreProduct storeProduct) async {
    // 先确认微信可用再下单，避免产生永远付不了的 pending 孤儿订单
    // （服务端查单兜底会取「最新 pending 单」，孤儿订单会干扰 restore）
    final installed = await _isWeChatInstalled();
    if (!installed) {
      if (kDebugMode) print('WeChat not installed');
      return null;
    }

    final data = await _invokeAsMap(
      'planbook-wechatpay-create-order',
      body: {
        'product_id': storeProduct.id.split(':').first,
      },
    );
    if (data == null || data['success'] != true) return null;

    final payParams = data['pay_params'] as Map<String, dynamic>?;
    final outTradeNo = data['out_trade_no'] as String?;
    if (payParams == null || outTradeNo == null) return null;

    final completer = Completer<void>();
    var paidOk = false;
    FluwxCancelable? sub;
    sub = _fluwx.addSubscriber((resp) {
      if (resp is WeChatPaymentResponse) {
        paidOk = resp.isSuccessful;
        if (!completer.isCompleted) completer.complete();
        sub?.cancel();
      }
    });

    try {
      final launched = await _fluwx.pay(
        which: Payment(
          appId: payParams['appId'] as String,
          partnerId: payParams['partnerId'] as String,
          prepayId: payParams['prepayId'] as String,
          packageValue: payParams['packageValue'] as String? ?? 'Sign=WXPay',
          nonceStr: payParams['nonceStr'] as String,
          timestamp: int.tryParse('${payParams['timeStamp']}') ?? 0,
          sign: payParams['sign'] as String,
        ),
      );

      if (!launched) return null;

      // 客户端回调不可靠；无论 SDK 结果如何都走服务端按本单查单
      try {
        await completer.future.timeout(const Duration(seconds: 90));
      } on Exception catch (_) {
        // ignore — 依赖 query
      }
    } finally {
      // 任何异常路径都必须取消订阅，避免泄漏全局 subscriber
      sub.cancel();
    }

    // SDK 明确返回失败（用户取消等）时订单几乎不可能已支付，但仍做一次
    // 轻量确认：回调可能先于 SDK 返回到账（付完款立刻取消的竞态），漏掉
    // 会让已扣款用户被误判为失败。未收到回调（超时）则按成功路径多轮查单。
    if (completer.isCompleted && !paidOk) {
      return _confirmOrder(outTradeNo, allowEntitlementFallback: false);
    }
    for (var i = 0; i < 3; i++) {
      // 首次立即查；后续重试前等待，给服务端回调留同步时间
      if (i > 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      // FunctionException（非 2xx）等瞬时错误不应中断重试：用户可能已扣款
      final id = await _confirmOrder(
        outTradeNo,
        allowEntitlementFallback: false,
      );
      if (id != null) return id;
    }
    return null;
  }

  Future<bool> _isWeChatInstalled() async {
    try {
      return await _fluwx.isWeChatInstalled;
    } on Exception catch (_) {
      // 平台无插件实现时按未安装处理
      return false;
    }
  }

  /// invoke 包装：非 2xx 抛 FunctionException、网络错误等统一返回 null，
  /// 由调用方决定是否重试
  Future<Map<String, dynamic>?> _invokeAsMap(
    String fn, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _supabase?.functions.invoke(fn, body: body);
      if (response == null ||
          response.status != 200 ||
          response.data is! Map<String, dynamic>) {
        return null;
      }
      return response.data as Map<String, dynamic>;
    } on FunctionException catch (e) {
      if (kDebugMode) print('$fn FunctionException: $e');
      return null;
    } on Exception catch (e) {
      if (kDebugMode) print('$fn error: $e');
      return null;
    }
  }

  /// 按 out_trade_no 查单；成功则刷新并返回本单 product_id
  ///
  /// [allowEntitlementFallback] 为 true 时，服务端未返回 product_id 才回退到
  /// 当前有效权益（restore 场景）；购买确认必须为 false，避免已有会员冒充成功
  Future<String?> _confirmOrder(
    String outTradeNo, {
    bool allowEntitlementFallback = true,
  }) async {
    final data = await _invokeAsMap(
      'planbook-wechatpay-query',
      body: {'out_trade_no': outTradeNo},
    );
    if (data == null || data['success'] != true) return null;
    // 刷新 profile 仅为同步缓存，失败不影响已确认的订单结果
    try {
      await UsersRepository.instance.getUserProfile(force: true);
    } on Exception catch (e) {
      if (kDebugMode) print('Wechat _confirmOrder 刷新 profile 失败: $e');
    }
    final productId = data['product_id'] as String?;
    if (productId != null) return productId;
    if (!allowEntitlementFallback) return null;
    return UsersRepository.instance.getActiveEntitlementProductId();
  }

  @override
  Future<String?> restore() async {
    final data = await _invokeAsMap('planbook-wechatpay-query');
    if (data == null || data['success'] != true) return null;
    // 与支付宝 restore 同构：只负责「补发未同步订单」，无 pending 单可补
    // （无 product_id）时返回 null，不拿当前有效权益冒充恢复结果，
    // 避免短路掉其他渠道的 pending 单补发。
    final productId = data['product_id'] as String?;
    if (productId == null) return null;
    // 刷新 profile 仅为同步缓存，失败不影响已确认的订单结果
    try {
      await UsersRepository.instance.getUserProfile(force: true);
    } on Exception catch (e) {
      if (kDebugMode) print('Wechat restore 刷新 profile 失败: $e');
    }
    return productId;
  }

  @override
  Future<String?> getActiveIdentifier() async {
    return UsersRepository.instance.getActiveEntitlementProductId();
  }

  @override
  Future<List<StoreProduct>> getStoreProducts() async {
    try {
      final response = await _supabase
          ?.from('store_products')
          .select()
          .eq('is_enabled', true)
          .isFilter('deleted_at', null)
          .order('order', ascending: true);
      final products = response?.map(StoreProduct.fromJson).toList() ?? [];
      if (products.isNotEmpty) {
        _cachedStoreProducts = products;
        return products;
      }
    } on Exception catch (e) {
      if (kDebugMode) print('Wechat getStoreProducts error: $e');
    }
    return _cachedStoreProducts ?? [];
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
