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
  });

  final PageStatus status;
  final String? activeProductId;

  final List<StoreProduct> storeProducts;
  final StoreProduct? selectedStoreProduct;

  final bool isAgreedToConditions;

  final String? userId;

  final String? savePercentId;
  final int? savePercent;

  bool get isPremium => activeProductId != null;
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
  ];

  AppPurchasesState copyWith({
    PageStatus? status,
    String? activeProductId,
    List<StoreProduct>? storeProducts,
    StoreProduct? selectedStoreProduct,
    String? userId,
    bool? isAgreedToConditions,
    String? savePercentId,
    int? savePercent,
  }) {
    return AppPurchasesState(
      status: status ?? this.status,
      activeProductId: activeProductId ?? this.activeProductId,
      storeProducts: storeProducts ?? this.storeProducts,
      selectedStoreProduct: selectedStoreProduct ?? this.selectedStoreProduct,
      userId: userId ?? this.userId,
      isAgreedToConditions: isAgreedToConditions ?? this.isAgreedToConditions,
      savePercentId: savePercentId ?? this.savePercentId,
      savePercent: savePercent ?? this.savePercent,
    );
  }
}
