enum AppChannelType {
  /// App Store & Google Play
  main,

  /// 国内版本应用市场
  cn,

  /// 自分发，腾讯云存储
  cloud,
}

class AppChannel {
  AppChannel._();

  static final AppChannel instance = AppChannel._();

  AppChannelType? _type;
  AppChannelType get type {
    if (_type == null) throw Exception('AppChannel not initialized');
    return _type!;
  }

  set type(AppChannelType type) {
    instance._type = type;
  }

  static bool get isAndroidChina =>
      instance.type == AppChannelType.cn ||
      instance.type == AppChannelType.cloud;

  static bool get isCloud => instance.type == AppChannelType.cloud;
}
