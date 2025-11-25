import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/app/purchases/model/app_purchases_repository.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

part 'app_purchases_event.dart';
part 'app_purchases_state.dart';

class AppPurchasesBloc extends Bloc<AppPurchasesEvent, AppPurchasesState> {
  AppPurchasesBloc({
    required AppPurchasesRepository appPurchasesRepository,
  }) : _appPurchasesRepository = appPurchasesRepository,
       super(const AppPurchasesState()) {
    on<AppPurchasesSubscriptionRequested>(_onSubscriptionRequested);
    on<AppPurchasesPackageRequested>(_onPackageRequested);
    on<AppPurchasesRestored>(_onRestored);
    on<AppPurchasesLogin>(_onLogin);

    on<AppPurchasesPackageSelected>(_onPackageSelected);
    on<AppPurchasesPurchased>(_onPurchased);
    on<AppPurchasesSupportUsFullPrice>(_onSupportUsFullPrice);
  }

  final AppPurchasesRepository _appPurchasesRepository;

  bool get isPremium => state.isPremium;
  bool get isLifetime => state.isLifetime;

  Future<void> _onSubscriptionRequested(
    AppPurchasesSubscriptionRequested event,
    Emitter<AppPurchasesState> emit,
  ) async {
    // if (kDebugMode) {
    //   emit(
    //     state.copyWith(
    //       activeProductIdentifier: 'lifetime',
    //     ),
    //   );
    // }
    await emit.forEach(
      _appPurchasesRepository.getCustomerInfo(),
      onData: (info) {
        // if (kDebugMode) {
        //   return state.copyWith(
        //     activeProductIdentifier: 'lifetime',
        //   );
        // }
        return state.copyWith(
          activeProductIdentifier: info?.activeProductIdentifier,
        );
      },
    );
  }

  Future<void> _onPackageRequested(
    AppPurchasesPackageRequested event,
    Emitter<AppPurchasesState> emit,
  ) async {
    if (state.availablePackages.isNotEmpty) return;

    final availablePackages = await _appPurchasesRepository
        .getAvailablePackages();

    final activeProductIdentifier = await _appPurchasesRepository
        .getActiveProductIdentifier();
    final activePackage = availablePackages?.firstWhereOrNull(
      (e) => e.storeProduct.identifier == activeProductIdentifier,
    );

    final originalPackages = await _appPurchasesRepository
        .getOriginalPackages();

    emit(
      state.copyWith(
        activePackage: activePackage,
        availablePackages: availablePackages,
        selectedPackage: availablePackages?.firstWhereOrNull(
          (e) => e.isAnnual(),
        ),
        originalPackages: originalPackages,
      ),
    );
  }

  Future<void> _onLogin(
    AppPurchasesLogin event,
    Emitter<AppPurchasesState> emit,
  ) async {
    final id = event.userId;
    // 登录和这里都需要获取，两种逻辑相互独立
    await _onLimitFeatureRequested(userId: id);

    final appUserId = await _appPurchasesRepository.getAppUserID();
    if (appUserId == id) return;

    final info = await _appPurchasesRepository.logIn(id);
    emit(
      state.copyWith(
        activeProductIdentifier: info.customerInfo.activeProductIdentifier,
      ),
    );
  }

  Future<void> _onRestored(
    AppPurchasesRestored event,
    Emitter<AppPurchasesState> emit,
  ) async {
    final info = await _appPurchasesRepository.restore();
    emit(
      state.copyWith(
        activeProductIdentifier: info.activeProductIdentifier,
      ),
    );
  }

  Future<void> _onPackageSelected(
    AppPurchasesPackageSelected event,
    Emitter<AppPurchasesState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedPackage: event.package,
      ),
    );
  }

  Future<void> _onLimitFeatureRequested({String? userId}) async {
    if (userId == null) return;
  }

  Future<void> _onPurchased(
    AppPurchasesPurchased event,
    Emitter<AppPurchasesState> emit,
  ) async {
    final package =
        state.selectedPackage ??
        state.availablePackages.firstWhereOrNull(
          (e) => e.isAnnual(),
        ) ??
        state.availablePackages.first;

    final info = await _appPurchasesRepository.purchasePackage(
      package,
    );
    emit(
      state.copyWith(
        activeProductIdentifier: info.activeProductIdentifier,
        activePackage: package,
      ),
    );
  }

  Future<void> _onSupportUsFullPrice(
    AppPurchasesSupportUsFullPrice event,
    Emitter<AppPurchasesState> emit,
  ) async {
    final selectedPackage = state.selectedPackage;
    if (selectedPackage == null) return;

    final package =
        state.originalPackages.firstWhereOrNull(
          (e) => e.storeProduct.identifier.startsWith(
            selectedPackage.storeProduct.identifier,
          ),
        ) ??
        selectedPackage;

    final info = await _appPurchasesRepository.purchasePackage(
      package,
    );
    emit(
      state.copyWith(
        activeProductIdentifier: info.activeProductIdentifier,
        activePackage: package,
      ),
    );
  }
}
