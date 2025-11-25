part of 'app_purchases_bloc.dart';

class AppPurchasesState extends Equatable {
  const AppPurchasesState({
    this.selectedPackage,
    this.availablePackages = const [],
    this.activeProductIdentifier,
    this.activePackage,
    this.originalPackages = const [],
  });

  final String? activeProductIdentifier;
  final Package? activePackage;

  final List<Package> availablePackages;
  final Package? selectedPackage;

  final List<Package> originalPackages;

  bool get isPremium => activeProductIdentifier != null;
  bool get isLifetime =>
      activeProductIdentifier?.toLowerCase().contains('lifetime') ?? false;

  @override
  List<Object?> get props => [
        isPremium,
        isLifetime,
        activeProductIdentifier,
        selectedPackage,
        availablePackages,
        activePackage,
        originalPackages,
      ];

  AppPurchasesState copyWith({
    Package? selectedPackage,
    List<Package>? availablePackages,
    String? activeProductIdentifier,
    Package? activePackage,
    List<Package>? originalPackages,
  }) {
    return AppPurchasesState(
      selectedPackage: selectedPackage ?? this.selectedPackage,
      availablePackages: availablePackages ?? this.availablePackages,
      activeProductIdentifier:
          activeProductIdentifier ?? this.activeProductIdentifier,
      activePackage: activePackage ?? this.activePackage,
      originalPackages: originalPackages ?? this.originalPackages,
    );
  }
}
