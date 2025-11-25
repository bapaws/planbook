enum PageStatus {
  /// 页面初始化
  initial,

  /// 加载中
  loading,

  /// 加载、提交成功
  success,

  /// 加载、提交失败
  failure,

  /// 销毁、Pop
  dispose,
}

extension PageStatusX on PageStatus {
  bool get isInitial => this == PageStatus.initial;
  bool get isLoading => this == PageStatus.loading;
  bool get isSuccess => this == PageStatus.success;
  bool get isFailure => this == PageStatus.failure;
}
