import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final class StoreProduct extends Equatable {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.priceString,
    required this.currencyCode,
    this.description,
    this.subscriptionPeriod,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: json['price'] as double,
      priceString: json['price_string'] as String,
      currencyCode: json['currency_code'] as String,
      subscriptionPeriod: json['subscription_period'] as String?,
    );
  }

  factory StoreProduct.fromRevenueCat(Package package) {
    return StoreProduct(
      id: package.storeProduct.identifier,
      title: package.storeProduct.title,
      description: package.storeProduct.description,
      price: package.storeProduct.price,
      priceString: package.storeProduct.priceString,
      currencyCode: package.storeProduct.currencyCode,
      subscriptionPeriod: package.storeProduct.subscriptionPeriod,
    );
  }

  final String id;
  final String title;
  final String? description;
  final double price;
  final String priceString;
  final String currencyCode;
  final String? subscriptionPeriod;

  bool get isLifetime => id.toLowerCase().contains('lifetime');
  bool get isAnnual =>
      id.toLowerCase().contains('yearly') ||
      id.toLowerCase().contains('annual');

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'priceString': priceString,
    'currencyCode': currencyCode,
    'subscriptionPeriod': subscriptionPeriod,
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
  ];

  StoreProduct copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? priceString,
    String? currencyCode,
    String? subscriptionPeriod,
  }) {
    return StoreProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      priceString: priceString ?? this.priceString,
      currencyCode: currencyCode ?? this.currencyCode,
      subscriptionPeriod: subscriptionPeriod ?? this.subscriptionPeriod,
    );
  }

  @override
  String toString() {
    return 'StoreProduct(identifier: $id, title: $title, description: $description, price: $price, priceString: $priceString, currencyCode: $currencyCode, subscriptionPeriod: $subscriptionPeriod)';
  }
}
