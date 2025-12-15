import 'package:equatable/equatable.dart';

final class AppBackgroundEntity extends Equatable {
  const AppBackgroundEntity({
    required this.id,
    required this.name,
    required this.darkAsset,
    required this.lightAsset,
  });

  factory AppBackgroundEntity.fromJson(Map<String, dynamic> json) {
    return AppBackgroundEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      darkAsset: json['darkAsset'] as String,
      lightAsset: json['lightAsset'] as String,
    );
  }

  final String id;
  final String name;
  final String darkAsset;
  final String lightAsset;

  AppBackgroundEntity copyWith({
    String? id,
    String? name,
    String? darkAsset,
    String? lightAsset,
  }) {
    return AppBackgroundEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      darkAsset: darkAsset ?? this.darkAsset,
      lightAsset: lightAsset ?? this.lightAsset,
    );
  }

  @override
  List<Object?> get props => [id, name, darkAsset, lightAsset];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'darkAsset': darkAsset,
      'lightAsset': lightAsset,
    };
  }

  static List<AppBackgroundEntity> get all => [
    const AppBackgroundEntity(
      id: '1',
      name: 'Dot',
      darkAsset: 'assets/images/bg_dot_tile_dark.png',
      lightAsset: 'assets/images/bg_dot_tile_light.png',
    ),
    const AppBackgroundEntity(
      id: '2',
      name: 'Grid',
      darkAsset: 'assets/images/bg_grid_tile_dark.png',
      lightAsset: 'assets/images/bg_grid_tile_light.png',
    ),
  ];
}
