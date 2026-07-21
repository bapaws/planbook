// Supabase 增量同步相关工具函数。

/// 从 Supabase 返回的同步数据中提取 updated_at / created_at / deleted_at
/// 的最大毫秒时间戳，用于作为下一轮增量同步的游标。
///
/// 返回值 null 表示列表为空或没有任何时间字段。
int? maxTimestampFromSyncItems(List<Map<String, dynamic>> items) {
  int? maxTimestamp;
  for (final item in items) {
    for (final key in ['updated_at', 'created_at', 'deleted_at']) {
      final value = item[key];
      if (value is String) {
        final millis = DateTime.parse(value).millisecondsSinceEpoch;
        if (maxTimestamp == null || millis > maxTimestamp) {
          maxTimestamp = millis;
        }
      }
    }
  }
  return maxTimestamp;
}
