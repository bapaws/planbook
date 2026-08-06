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

  /// 解析 ISO-8601 订阅周期，例如 P1Y、P3Y、P1M
  (int, Unit)? get subscriptionPeriodParts {
    final period = subscriptionPeriod;
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

  bool get isAnnual {
    final parts = subscriptionPeriodParts;
    if (parts != null) return parts.$2 == Unit.year && parts.$1 >= 1;
    // 兼容 RevenueCat / 旧数据：无 subscriptionPeriod 时按 ID 回退
    return id.toLowerCase().contains('yearly') ||
        id.toLowerCase().contains('annual');
  }

  /// 单年档（P1Y）；多年档（如 P3Y）不算进「年度」推荐/节省计算
  bool get isSingleYearAnnual {
    final parts = subscriptionPeriodParts;
    if (parts != null) return parts.$2 == Unit.year && parts.$1 == 1;
    return isAnnual && !id.toLowerCase().contains('3year');
  }

  bool get isMonthly {
    final parts = subscriptionPeriodParts;
    if (parts != null) return parts.$2 == Unit.month && parts.$1 >= 1;
    return id.toLowerCase().contains('monthly');
  }

  String displayTitle(AppLocalizations l10n, {bool preferDuration = false}) {
    if (isLifetime) return l10n.productTitleLifetime;

    // 支付宝等国内渠道按实际时长显示：1年 / 3年 / 1个月
    if (preferDuration) {
      final parts = subscriptionPeriodParts;
      if (parts != null) {
        final (amount, unit) = parts;
        return switch (unit) {
          Unit.year => l10n.productTitleYears(amount),
          Unit.month => l10n.productTitleMonths(amount),
          _ => l10n.productTitleAnnual,
        };
      }
    }

    // iOS / Google Play 等自动续订渠道保持原有分类标签：年度 / 月度
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
    'price_string': priceString,
    'currency_code': currencyCode,
    'subscription_period': subscriptionPeriod,
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
    return 'StoreProduct('
        'identifier: $id, '
        'title: $title, '
        'description: $description, '
        'price: $price, '
        'priceString: $priceString, '
        'currencyCode: $currencyCode, '
        'subscriptionPeriod: $subscriptionPeriod, '
        'introductoryPrice: $introductoryPrice)';
  }
}
