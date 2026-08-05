part of 'app_purchases_bloc.dart';

class AppPurchasesState extends Equatable {
  const AppPurchasesState({
    this.status = PageStatus.initial,
    this.activeProductId,
    this.storeProducts = const [],
    this.selectedStoreProduct,
    this.userId,
    this.isAgreedToConditions = false,
    this.savePercentId,
    this.savePercent,
    this.isRestoreFailure = false,
    this.entitlementJustGranted = false,
  });

  final PageStatus status;
  final String? activeProductId;

  final List<StoreProduct> storeProducts;
  final StoreProduct? selectedStoreProduct;

  final bool isAgreedToConditions;

  final String? userId;

  final String? savePercentId;
  final int? savePercent;

  /// 当前 failure 是否来自「恢复购买」，
  /// 页面据此区分恢复失败与购买失败的提示文案
  final bool isRestoreFailure;

  /// 购买/恢复刚成功且会员已写入状态，页面据此提示并关闭。
  /// 不能依赖 isPremium 翻转：已是会员再买时 isPremium 不会变化。
  final bool entitlementJustGranted;

  bool get isPremium => kDebugMode || activeProductId != null;
  bool get isLifetime =>
      activeProductId?.toLowerCase().contains('lifetime') ?? false;

  @override
  List<Object?> get props => [
    status,
    isPremium,
    isLifetime,
    activeProductId,
    storeProducts,
    selectedStoreProduct,
    userId,
    isAgreedToConditions,
    savePercentId,
    savePercent,
    isRestoreFailure,
    entitlementJustGranted,
  ];

  AppPurchasesState copyWith({
    PageStatus? status,
    ValueGetter<String?>? activeProductId,
    List<StoreProduct>? storeProducts,
    StoreProduct? selectedStoreProduct,
    ValueGetter<String?>? userId,
    bool? isAgreedToConditions,
    String? savePercentId,
    int? savePercent,
    bool? isRestoreFailure,
    bool? entitlementJustGranted,
  }) {
    return AppPurchasesState(
      status: status ?? this.status,
      activeProductId: activeProductId != null
          ? activeProductId()
          : this.activeProductId,
      storeProducts: storeProducts ?? this.storeProducts,
      selectedStoreProduct: selectedStoreProduct ?? this.selectedStoreProduct,
      userId: userId != null ? userId() : this.userId,
      isAgreedToConditions: isAgreedToConditions ?? this.isAgreedToConditions,
      savePercentId: savePercentId ?? this.savePercentId,
      savePercent: savePercent ?? this.savePercent,
      isRestoreFailure: isRestoreFailure ?? this.isRestoreFailure,
      entitlementJustGranted:
          entitlementJustGranted ?? this.entitlementJustGranted,
    );
  }
}
