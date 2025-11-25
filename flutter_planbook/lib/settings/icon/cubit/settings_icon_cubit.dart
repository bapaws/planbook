import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:flutter_planbook/settings/icon/model/app_icons.dart';
import 'package:planbook_core/planbook_core.dart';

part 'settings_icon_state.dart';

class SettingsIconCubit extends Cubit<SettingsIconState> {
  SettingsIconCubit() : super(const SettingsIconState());

  Future<void> onRequested() async {
    if (!await FlutterDynamicIconPlus.supportsAlternateIcons) return;

    final name = await FlutterDynamicIconPlus.alternateIconName;
    if (name == null) return;

    emit(
      state.copyWith(
        icon: AppIcons.values.firstWhereOrNull(
          (e) => e.iconName == name,
        ),
      ),
    );
  }

  Future<void> onIconChanged(AppIcons icon) async {
    if (!await FlutterDynamicIconPlus.supportsAlternateIcons) return;

    await FlutterDynamicIconPlus.setAlternateIconName(
      iconName: icon.iconName,
    );

    emit(
      state.copyWith(
        status: PageStatus.success,
        icon: icon,
      ),
    );
  }
}
