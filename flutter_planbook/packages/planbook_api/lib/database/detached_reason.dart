/// 分离原因（用于标识分离实例的创建原因）
///
/// 当用户对重复任务的某个实例进行操作时，会创建一个分离实例。
/// 这个枚举用于标识分离的原因。
enum DetachedReason {
  /// 完成该实例
  completed,

  /// 跳过该实例
  skipped,

  /// 修改该实例（时间、标题等）
  modified;

  /// 从字符串创建（用于数据库反序列化）
  static DetachedReason? fromString(String? value) {
    if (value == null) return null;
    return DetachedReason.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DetachedReason.modified,
    );
  }
}
