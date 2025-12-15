part of 'settings_background_cubit.dart';

final class SettingsBackgroundState extends Equatable {
  const SettingsBackgroundState({
    this.assets = const <AppBackgroundEntity>[],
    this.selectedAssetId = '',
  });

  final List<AppBackgroundEntity> assets;

  final String selectedAssetId;

  @override
  List<Object> get props => [assets, selectedAssetId];

  SettingsBackgroundState copyWith({
    List<AppBackgroundEntity>? assets,
    String? selectedAssetId,
  }) {
    return SettingsBackgroundState(
      assets: assets ?? this.assets,
      selectedAssetId: selectedAssetId ?? this.selectedAssetId,
    );
  }
}
