import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'about_state.dart';

class AboutCubit extends Cubit<AboutState> {
  AboutCubit() : super(const AboutState());

  Future<void> onRequested() async {
    final package = await PackageInfo.fromPlatform();
    emit(
      state.copyWith(
        appName: () => package.appName,
        appVersion: () => package.version,
        builderNumber: () => package.buildNumber,
      ),
    );
  }
}
