part of 'app_purchases_bloc.dart';

sealed class AppPurchasesEvent extends Equatable {
  const AppPurchasesEvent();

  @override
  List<Object> get props => [];
}

class AppPurchasesRequested extends AppPurchasesEvent {
  const AppPurchasesRequested();
}

class AppPurchasesUserRequested extends AppPurchasesEvent {
  const AppPurchasesUserRequested();
}

class AppPurchasesRestored extends AppPurchasesEvent {
  const AppPurchasesRestored();
}

class AppPurchasesLogin extends AppPurchasesEvent {
  const AppPurchasesLogin({required this.userId});

  final String userId;
}

class AppPurchasesProductSelected extends AppPurchasesEvent {
  const AppPurchasesProductSelected(this.product);

  final StoreProduct product;
}

class AppPurchasesPurchased extends AppPurchasesEvent {
  const AppPurchasesPurchased();
}

class AppPurchasesSupportUsFullPrice extends AppPurchasesEvent {
  const AppPurchasesSupportUsFullPrice();
}

class AppPurchasesAgreedToConditions extends AppPurchasesEvent {
  const AppPurchasesAgreedToConditions({required this.isAgreed});

  final bool isAgreed;

  @override
  List<Object> get props => [isAgreed];
}
