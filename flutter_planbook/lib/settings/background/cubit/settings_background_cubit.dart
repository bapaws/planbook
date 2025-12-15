import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/settings/app_background_entity.dart';
import 'package:planbook_repository/settings/settings_repository.dart';

part 'settings_background_state.dart';

class SettingsBackgroundCubit extends Cubit<SettingsBackgroundState> {
  SettingsBackgroundCubit({
    required SettingsRepository settingsRepository,
    required AppLocalizations l10n,
  }) : _settingsRepository = settingsRepository,
       _l10n = l10n,
       super(const SettingsBackgroundState());

  final SettingsRepository _settingsRepository;
  final AppLocalizations _l10n;

  Future<void> onRequested() async {
    final names = [_l10n.dot, _l10n.grid];
    final assets = AppBackgroundEntity.all;
    for (var i = 0; i < assets.length; i++) {
      assets[i] = assets[i].copyWith(name: names[i]);
    }
    emit(
      state.copyWith(
        assets: assets,
        selectedAssetId: _settingsRepository.backgroundAsset?.id,
      ),
    );
  }

  Future<void> onAssetSelected(String assetId) async {
    final asset = state.assets.firstWhere((e) => e.id == assetId);
    await _settingsRepository.saveBackgroundAsset(asset);
    emit(state.copyWith(selectedAssetId: assetId));
  }
}
