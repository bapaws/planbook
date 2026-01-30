import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
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
    on<AppPurchasesRequested>(_onRequested);
    on<AppPurchasesUserRequested>(_onUserRequested);
    on<AppPurchasesRestored>(_onRestored);
    on<AppPurchasesLogin>(_onLogin);

    on<AppPurchasesProductSelected>(_onProductSelected);
    on<AppPurchasesPurchased>(_onPurchased);
    on<AppPurchasesSupportUsFullPrice>(_onSupportUsFullPrice);
    on<AppPurchasesAgreedToConditions>(_onAgreedToConditions);
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
    emit(state.copyWith(status: PageStatus.loading));
    final storeProducts = (await AppPurchases.instance.getStoreProducts())
        .sorted((a, b) => a.price.compareTo(b.price));
    // if (kDebugMode) {
    //   emit(
    //     state.copyWith(
    //       activeProductIdentifier: 'lifetime',
    //     ),
    //   );
    //   return;
    // }

    final selectedStoreProduct = storeProducts.isEmpty
        ? null
        : storeProducts[storeProducts.length ~/ 2];
    final activeProductIdentifier = await AppPurchases.instance
        .getActiveIdentifier();
    emit(
      state.copyWith(
        status: PageStatus.success,
        activeProductId: activeProductIdentifier,
        storeProducts: storeProducts,
        selectedStoreProduct: selectedStoreProduct,
        savePercentId: selectedStoreProduct?.id,
      ),
    );
  }

  Future<void> _onUserRequested(
    AppPurchasesUserRequested event,
    Emitter<AppPurchasesState> emit,
  ) async {
    await emit.forEach(
      _usersRepository.onAuthStateChange,
      onData: (user) {
        final id = user?.session?.user.id;
        if (id == null || id == state.userId) return state;
        add(AppPurchasesLogin(userId: id));
        return state.copyWith(
          userId: id,
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

    final appUserId = await AppPurchases.instance.getAppUserID();
    if (appUserId == id) return;

    final activeProductIdentifier = await AppPurchases.instance.logIn(id);
    emit(
      state.copyWith(
        activeProductId: activeProductIdentifier,
      ),
    );
  }

  Future<void> _onRestored(
    AppPurchasesRestored event,
    Emitter<AppPurchasesState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    final activeProductIdentifier = await AppPurchases.instance.restore();
    emit(
      state.copyWith(
        status: PageStatus.success,
        activeProductId: activeProductIdentifier,
      ),
    );
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
    emit(state.copyWith(status: PageStatus.loading));
    final storeProduct =
        state.selectedStoreProduct ??
        state.storeProducts.firstWhereOrNull((e) => e.isAnnual) ??
        state.storeProducts.first;

    final activeProductIdentifier = await AppPurchases.instance.purchase(
      storeProduct,
    );
    emit(
      state.copyWith(
        status: activeProductIdentifier == null
            ? PageStatus.failure
            : PageStatus.success,
        activeProductId: activeProductIdentifier,
      ),
    );
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
    emit(
      state.copyWith(
        activeProductId: activeProductIdentifier,
      ),
    );
  }

  Future<void> _onAgreedToConditions(
    AppPurchasesAgreedToConditions event,
    Emitter<AppPurchasesState> emit,
  ) async {
    emit(state.copyWith(isAgreedToConditions: event.isAgreed));
  }
}

extension AppPurchasesBlocX on BuildContext {
  bool get isPremium => read<AppPurchasesBloc>().state.isPremium;
}
