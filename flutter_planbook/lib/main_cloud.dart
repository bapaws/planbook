import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_planbook/bootstrap.dart';
import 'package:flutter_planbook/core/model/app_channel.dart';

/// iPadOS 26 bug workaround: Drawer/Dialog/BottomSheet closes immediately after opening
/// https://stackoverflow.com/questions/79816937
/// https://github.com/flutter/flutter/issues/175606#issuecomment-3453392532
/// 过滤掉 position 为 (0, 0) 的 PointerEvent，避免误触发关闭
class FilteringFlutterBinding extends WidgetsFlutterBinding {
  @override
  void handlePointerEvent(PointerEvent event) {
    if (event.position == Offset.zero) {
      return;
    }
    super.handlePointerEvent(event);
  }
}

/// 通过屏幕尺寸检测是否是 iPad
/// iPad 的最短边通常 >= 600 逻辑像素
bool _isIPad() {
  final views = ui.PlatformDispatcher.instance.views;
  if (views.isEmpty) return false;

  final view = views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  final shortSide = size.width < size.height ? size.width : size.height;

  // iPad 最短边至少 600pt（iPad mini 约 744pt）
  return shortSide >= 600;
}

/// 检测是否需要使用 FilteringFlutterBinding
/// 仅在 iPadOS 26.1 及以上版本使用（iPhone 无此问题）
bool _shouldUseFilteringBinding() {
  if (!Platform.isIOS) return false;
  if (!_isIPad()) return false;

  try {
    // Platform.operatingSystemVersion 格式类似: "Version 26.1 (Build 23A339)"
    final versionString = Platform.operatingSystemVersion;
    final match = RegExp(r'Version (\d+)\.(\d+)').firstMatch(versionString);
    if (match != null) {
      final major = int.parse(match.group(1)!);
      final minor = int.parse(match.group(2)!);
      // iPadOS 26.1 及以上
      return major > 26 || (major == 26 && minor >= 1);
    }
  } on Exception catch (_) {
    // 解析失败时不使用 workaround
  }
  return false;
}

void main() async {
  AppChannel.instance.type = AppChannelType.cloud;

  final WidgetsBinding widgetsBinding;

  if (_shouldUseFilteringBinding()) {
    widgetsBinding = FilteringFlutterBinding();
  } else {
    widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  }

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['assets/google_fonts'], license);
  });

  await bootstrap();
}
