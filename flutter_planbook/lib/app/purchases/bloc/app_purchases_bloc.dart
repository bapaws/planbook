import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/purchases/model/app_pro_features.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:flutter_planbook/core/purchases/store_product.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'app_purchases_event.dart';
part 'app_purchases_state.dart';

class AppPurchasesBloc extends Bloc<AppPurchasesEvent, AppPurchasesState> {
  AppPurchasesBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required TagsRepository tagsRepository,
    required UsersRepository usersRepository,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _tagsRepository = tagsRepository,
       _usersRepository = usersRepository,
       super(const AppPurchasesState()) {
    on<AppPurchasesRequested>(_onRequested, transformer: restartable());
    on<AppPurchasesUserRequested>(_onUserRequested, transformer: sequential());
    // 购买/恢复是提交型操作：丢弃进行中的重复事件，防止连点导致双扣
    on<AppPurchasesRestored>(_onRestored, transformer: droppable());
    on<AppPurchasesLogin>(_onLogin, transformer: sequential());

    on<AppPurchasesProductSelected>(
      _onProductSelected,
      transformer: sequential(),
    );
    on<AppPurchasesPurchased>(_onPurchased, transformer: droppable());
    on<AppPurchasesSupportUsFullPrice>(
      _onSupportUsFullPrice,
      transformer: droppable(),
    );
    on<AppPurchasesAgreedToConditions>(
      _onAgreedToConditions,
      transformer: sequential(),
    );
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final TagsRepository _tagsRepository;

  final UsersRepository _usersRepository;

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

  Future<void> _onRequested(
    AppPurchasesRequested event,
    Emitter<AppPurchasesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PageStatus.loading,
        isRestoreFailure: false,
        entitlementJustGranted: false,
      ),
    );

    final fetchedProducts = (await AppPurchases.instance.getStoreProducts())
        .sorted((a, b) => a.price.compareTo(b.price));

    // 新结果为空时保留上次非空列表，避免重叠请求或异常导致页面空白
    final storeProducts = fetchedProducts.isNotEmpty
        ? fetchedProducts
        : state.storeProducts;

    final selectedStoreProduct = storeProducts.isEmpty
        ? null
        : storeProducts[storeProducts.length ~/ 2];

    // 相对月费计算年费节省比例，用于「最划算」角标
    final monthly = storeProducts.firstWhereOrNull((e) => e.isMonthly);
    final annual = storeProducts.firstWhereOrNull(
      (e) => e.isSingleYearAnnual,
    );
    int? savePercent;
    String? savePercentId;
    if (monthly != null &&
        annual != null &&
        monthly.price > 0 &&
        annual.price > 0) {
      final percent = ((1 - annual.price / (monthly.price * 12)) * 100).round();
      if (percent > 0) {
        savePercent = percent;
        savePercentId = annual.id;
      }
    }

    final activeProductIdentifier = await AppPurchases.instance
        .getActiveIdentifier();
    emit(
      state.copyWith(
        status: PageStatus.success,
        activeProductId: () =>
            kDebugMode ? 'lifetime' : activeProductIdentifier,
        storeProducts: storeProducts,
        selectedStoreProduct: selectedStoreProduct,
        savePercentId: savePercentId,
        savePercent: savePercent,
        entitlementJustGranted: false,
      ),
    );
    _syncPremiumWidget();
  }

  Future<void> _onUserRequested(
    AppPurchasesUserRequested event,
    Emitter<AppPurchasesState> emit,
  ) async {
    await emit.forEach(
      _usersRepository.onAuthStateChange,
      onData: (user) {
        final id = user?.session?.user.id;
        // 登出时必须清空会员信息，否则下一位登录用户会继承上一位的会员状态
        if (id == null) {
          final next = state.copyWith(
            userId: () => null,
            activeProductId: () => null,
          );
          _syncPremiumWidget(next);
          return next;
        }
        if (id == state.userId) return state;
        add(AppPurchasesLogin(userId: id));
        return state.copyWith(
          userId: () => id,
        );
      },
    );
  }

  Future<void> _onLogin(
    AppPurchasesLogin event,
    Emitter<AppPurchasesState> emit,
  ) async {
    final id = event.userId;
    // 登录和这里都需要获取，两种逻辑相互独立
    await _onLimitFeatureRequested(userId: id);
    final activeProductIdentifier = await AppPurchases.instance.logIn(id);
    emit(
      state.copyWith(
        activeProductId: () => activeProductIdentifier,
      ),
    );
    _syncPremiumWidget();
  }

  Future<void> _onRestored(
    AppPurchasesRestored event,
    Emitter<AppPurchasesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PageStatus.loading,
        isRestoreFailure: false,
        entitlementJustGranted: false,
      ),
    );
    final activeProductIdentifier = await AppPurchases.instance.restore();
    if (activeProductIdentifier == null) {
      // 恢复不到任何购买记录必须明确失败并反馈，
      // 无条件 success 会让已付款但未到账的用户得不到任何提示
      emit(
        state.copyWith(
          status: PageStatus.failure,
          isRestoreFailure: true,
          activeProductId: () => null,
          entitlementJustGranted: false,
        ),
      );
      _syncPremiumWidget();
      return;
    }
    emit(
      state.copyWith(
        status: PageStatus.success,
        activeProductId: () => activeProductIdentifier,
        entitlementJustGranted: true,
      ),
    );
    _syncPremiumWidget();
  }

  Future<void> _onProductSelected(
    AppPurchasesProductSelected event,
    Emitter<AppPurchasesState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedStoreProduct: event.product,
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
    emit(
      state.copyWith(
        status: PageStatus.loading,
        isRestoreFailure: false,
        entitlementJustGranted: false,
      ),
    );
    final storeProduct =
        state.selectedStoreProduct ??
        state.storeProducts.firstWhereOrNull((e) => e.isAnnual) ??
        state.storeProducts.firstWhereOrNull((e) => true);

    // 商品列表还没加载出来时直接失败，而不是抛 StateError
    if (storeProduct == null) {
      emit(
        state.copyWith(
          status: PageStatus.failure,
          entitlementJustGranted: false,
        ),
      );
      return;
    }

    try {
      final activeProductIdentifier = await AppPurchases.instance.purchase(
        storeProduct,
        chinaPayMethod: event.chinaPayMethod,
      );
      // 失败时不传 activeProductId（copyWith 保留原值）：
      // 一次失败的购买不能清掉已有的有效会员
      final granted = activeProductIdentifier != null;
      emit(
        state.copyWith(
          status: granted ? PageStatus.success : PageStatus.failure,
          activeProductId: granted ? () => activeProductIdentifier : null,
          entitlementJustGranted: granted,
        ),
      );
      _syncPremiumWidget();
    } on Object catch (e) {
      if (kDebugMode) print('AppPurchasesPurchased error: $e');
      emit(
        state.copyWith(
          status: PageStatus.failure,
          entitlementJustGranted: false,
        ),
      );
    }
  }

  Future<void> _onSupportUsFullPrice(
    AppPurchasesSupportUsFullPrice event,
    Emitter<AppPurchasesState> emit,
  ) async {
    final selectedStoreProduct = state.selectedStoreProduct;
    if (selectedStoreProduct == null) return;

    final activeProductIdentifier = await AppPurchases.instance.purchase(
      selectedStoreProduct,
    );
    // 与 _onPurchased 同理：失败保留已有会员状态
    final granted = activeProductIdentifier != null;
    emit(
      state.copyWith(
        activeProductId: granted ? () => activeProductIdentifier : null,
        entitlementJustGranted: granted,
      ),
    );
    _syncPremiumWidget();
  }

  Future<void> _onAgreedToConditions(
    AppPurchasesAgreedToConditions event,
    Emitter<AppPurchasesState> emit,
  ) async {
    emit(state.copyWith(isAgreedToConditions: event.isAgreed));
  }

  /// 把当前会员状态同步给时间块小组件。未打开过 App 时 native 缺省为非会员。
  void _syncPremiumWidget([AppPurchasesState? next]) {
    unawaited(
      AppHomeWidget.syncPremium(isPremium: (next ?? state).isPremium),
    );
  }
}

extension AppPurchasesBlocX on BuildContext {
  bool get isPremium => read<AppPurchasesBloc>().state.isPremium;
}
