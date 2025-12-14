import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/app/purchases/model/app_pro_features.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

part 'app_purchases_event.dart';
part 'app_purchases_state.dart';

class AppPurchasesBloc extends Bloc<AppPurchasesEvent, AppPurchasesState> {
  AppPurchasesBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required TagsRepository tagsRepository,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _tagsRepository = tagsRepository,
       super(const AppPurchasesState()) {
    on<AppPurchasesSubscriptionRequested>(_onSubscriptionRequested);
    on<AppPurchasesPackageRequested>(_onPackageRequested);
    on<AppPurchasesRestored>(_onRestored);
    on<AppPurchasesLogin>(_onLogin);

    on<AppPurchasesPackageSelected>(_onPackageSelected);
    on<AppPurchasesPurchased>(_onPurchased);
    on<AppPurchasesSupportUsFullPrice>(_onSupportUsFullPrice);
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final TagsRepository _tagsRepository;

  bool get isPremium => state.isPremium;
  bool get isLifetime => state.isLifetime;

  Future<bool> isTaskLimitReached() async {
    if (isPremium) return false;
    final count = await _tasksRepository.getTotalCount();
    return count >= AppProFeatures.task.basicTotal;
  }

  Future<bool> isTagLimitReached() async {
    if (isPremium) return false;
    final count = await _tagsRepository.getTotalCount();
    return count >= AppProFeatures.tag.basicTotal;
  }

  Future<bool> isNoteLimitReached() async {
    if (isPremium) return false;
    final count = await _notesRepository.getTotalCount();
    return count >= AppProFeatures.note.basicTotal;
  }

  Future<void> _onSubscriptionRequested(
    AppPurchasesSubscriptionRequested event,
    Emitter<AppPurchasesState> emit,
  ) async {
    if (kDebugMode) {
      emit(
        state.copyWith(
          activeProductIdentifier: 'lifetime',
        ),
      );
    }
    await emit.forEach(
      AppPurchases.instance.getCustomerInfo(),
      onData: (info) {
        if (kDebugMode) {
          return state.copyWith(
            activeProductIdentifier: 'lifetime',
          );
        }
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

    final availablePackages = await AppPurchases.instance
        .getAvailablePackages();

    final activeProductIdentifier = await AppPurchases.instance
        .getActiveProductIdentifier();
    final activePackage = availablePackages?.firstWhereOrNull(
      (e) => e.storeProduct.identifier == activeProductIdentifier,
    );

    final originalPackages = await AppPurchases.instance.getOriginalPackages();

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

    final appUserId = await AppPurchases.instance.getAppUserID();
    if (appUserId == id) return;

    final info = await AppPurchases.instance.logIn(id);
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
    final info = await AppPurchases.instance.restore();
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

    final info = await AppPurchases.instance.purchasePackage(
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

    final info = await AppPurchases.instance.purchasePackage(
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
