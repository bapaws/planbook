import 'dart:io';

import 'package:flutter/foundation.dart';

/// 是否为鸿蒙（HarmonyOS NEXT / OHOS）平台。
///
/// OpenHarmony Flutter 分支中 [Platform.operatingSystem] 返回 `ohos`；
/// 官方 SDK 上该判断恒为 false，三端可共用同一份代码。
final bool kIsOhos = !kIsWeb && Platform.operatingSystem == 'ohos';
