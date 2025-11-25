import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part 'settings_home_event.dart';
part 'settings_home_state.dart';

class SettingsHomeBloc extends Bloc<SettingsHomeEvent, SettingsHomeState> {
  SettingsHomeBloc({
    required SettingsRepository settingsRepository,
  }) : _settingsRepository = settingsRepository,
       super(const SettingsHomeState()) {
    on<SettingsHomeRequested>(_onRequested);
  }

  final SettingsRepository _settingsRepository;

  Future<void> _onRequested(
    SettingsHomeRequested event,
    Emitter<SettingsHomeState> emit,
  ) async {
    final info = await Purchases.getCustomerInfo();
    final entitlements = info.entitlements;
    final activeEntitlement = entitlements.active.values.firstWhereOrNull(
      (value) => value.isActive,
    );
    emit(
      state.copyWith(
        status: PageStatus.loading,
        darkMode: _settingsRepository.getDarkMode(),
        cloudSynchronizable: await _settingsRepository.getCloudSynchronizable(),
        isPremium: activeEntitlement != null,
      ),
    );
  }
}
