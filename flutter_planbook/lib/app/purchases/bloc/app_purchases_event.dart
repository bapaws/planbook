part of 'app_purchases_bloc.dart';

sealed class AppPurchasesEvent extends Equatable {
  const AppPurchasesEvent();

  @override
  List<Object> get props => [];
}

class AppPurchasesSubscriptionRequested extends AppPurchasesEvent {
  const AppPurchasesSubscriptionRequested();
}

class AppPurchasesPackageRequested extends AppPurchasesEvent {
  const AppPurchasesPackageRequested();
}

class AppPurchasesRestored extends AppPurchasesEvent {
  const AppPurchasesRestored();
}

class AppPurchasesLogin extends AppPurchasesEvent {
  const AppPurchasesLogin({required this.userId});

  final String userId;
}

class AppPurchasesPackageSelected extends AppPurchasesEvent {
  const AppPurchasesPackageSelected(this.package);

  final Package package;
}

class AppPurchasesPurchased extends AppPurchasesEvent {
  const AppPurchasesPurchased();
}

class AppPurchasesSupportUsFullPrice extends AppPurchasesEvent {
  const AppPurchasesSupportUsFullPrice();
}
