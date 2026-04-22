import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:jiffy/jiffy.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as revenue_cat;

final class IntroductoryPrice extends Equatable {
  const IntroductoryPrice({
    required this.price,
    this.priceString,
    this.period,
    this.cycles,
  });

  factory IntroductoryPrice.fromJson(Map<String, dynamic> json) {
    return IntroductoryPrice(
      price: (json['price'] as num).toDouble(),
      priceString:
          json['price_string'] as String? ?? json['priceString'] as String?,
      period: json['period'] as String?,
      cycles: json['cycles'] as int?,
    );
  }

  factory IntroductoryPrice.fromRevenueCat(
    revenue_cat.IntroductoryPrice introductoryPrice,
  ) {
    return IntroductoryPrice(
      price: introductoryPrice.price,
      priceString: introductoryPrice.priceString,
      period: introductoryPrice.period,
      cycles: introductoryPrice.cycles,
    );
  }

  final double price;
  final String? priceString;
  final String? period;
  final int? cycles;

  bool get isFreeTrial => price == 0;

  Map<String, dynamic> toJson() => {
    'price': price,
    'price_string': priceString,
    'period': period,
    'cycles': cycles,
  };

  @override
  List<Object?> get props => [price, priceString, period, cycles];
}

final class StoreProduct extends Equatable {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.priceString,
    required this.currencyCode,
    this.description,
    this.subscriptionPeriod,
    this.introductoryPrice,
  });

  factory StoreProduct.fromRevenueCat(revenue_cat.Package package) {
    return StoreProduct(
      id: package.storeProduct.identifier,
      title: package.storeProduct.title,
      description: package.storeProduct.description,
      price: package.storeProduct.price,
      priceString: package.storeProduct.priceString,
      currencyCode: package.storeProduct.currencyCode,
      subscriptionPeriod: package.storeProduct.subscriptionPeriod,
      introductoryPrice: package.storeProduct.introductoryPrice == null
          ? null
          : IntroductoryPrice.fromRevenueCat(
              package.storeProduct.introductoryPrice!,
            ),
    );
  }

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: json['price'] as double,
      priceString: json['price_string'] as String,
      currencyCode: json['currency_code'] as String,
      subscriptionPeriod: json['subscription_period'] as String?,
      introductoryPrice:
          json['introductory_price'] != null &&
              json['introductory_price'] is Map
          ? IntroductoryPrice.fromJson(
              Map<String, dynamic>.from(json['introductory_price'] as Map),
            )
          : null,
    );
  }

  final String id;
  final String title;
  final String? description;
  final double price;
  final String priceString;
  final String currencyCode;
  final String? subscriptionPeriod;
  final IntroductoryPrice? introductoryPrice;

  bool get isLifetime => id.toLowerCase().contains('lifetime');
  bool get isAnnual =>
      id.toLowerCase().contains('yearly') ||
      id.toLowerCase().contains('annual');
  bool get isMonthly => id.toLowerCase().contains('monthly');

  String displayTitle(AppLocalizations l10n) {
    if (isLifetime) return l10n.productTitleLifetime;
    if (isAnnual) return l10n.productTitleAnnual;
    if (isMonthly) return l10n.productTitleMonthly;
    return title;
  }

  bool get hasFreeTrial => introductoryPrice?.isFreeTrial ?? false;
  (int, Unit)? get period {
    final period = introductoryPrice?.period;
    if (period == null) return null;
    final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(period);
    if (match == null) return null;
    final amount = int.tryParse(match.group(1) ?? '');
    if (amount == null) return null;
    final unit = switch (match.group(2)) {
      'D' => Unit.day,
      'W' => Unit.week,
      'M' => Unit.month,
      'Y' => Unit.year,
      _ => null,
    };
    if (unit == null) return null;
    return (amount, unit);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'priceString': priceString,
    'currencyCode': currencyCode,
    'subscriptionPeriod': subscriptionPeriod,
    'introductory_price': introductoryPrice?.toJson(),
  };

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    priceString,
    currencyCode,
    subscriptionPeriod,
    introductoryPrice,
  ];

  StoreProduct copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? priceString,
    String? currencyCode,
    String? subscriptionPeriod,
    IntroductoryPrice? introductoryPrice,
  }) {
    return StoreProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      priceString: priceString ?? this.priceString,
      currencyCode: currencyCode ?? this.currencyCode,
      subscriptionPeriod: subscriptionPeriod ?? this.subscriptionPeriod,
      introductoryPrice: introductoryPrice ?? this.introductoryPrice,
    );
  }

  @override
  String toString() {
    return 'StoreProduct(identifier: $id, title: $title, description: $description, price: $price, priceString: $priceString, currencyCode: $currencyCode, subscriptionPeriod: $subscriptionPeriod, introductoryPrice: $introductoryPrice)';
  }
}
