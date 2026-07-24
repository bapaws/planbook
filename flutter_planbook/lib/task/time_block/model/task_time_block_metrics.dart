/// 时间块视图布局常量与纯计算工具
abstract final class TaskTimeBlockMetrics {
  /// 每小时高度
  static const double hourHeight = 60;

  /// 最小任务块高度
  static const double minBlockHeight = 24;

  /// 拖拽落点对齐粒度（分钟）
  static const int snapMinutes = 5;

  /// 时间轴起始小时
  static const int startHour = 0;

  /// 时间轴结束小时
  static const int endHour = 24;

  /// 左侧时间刻度宽度
  static const double timeLabelWidth = 48;

  /// 上下边缘拖拽热区高度
  static const double resizeHandleHeight = 14;

  /// 默认任务时长（分钟）
  static const int defaultDurationMinutes = 60;

  /// 网格总高度
  static const double gridHeight = (endHour - startHour) * hourHeight;

  /// 一天总分钟数
  static const int dayMinutes = (endHour - startHour) * 60;

  /// 最小块对应的像素高度（对齐粒度）
  static const double minSnapHeight = snapMinutes / 60 * hourHeight;

  /// 预生成的整点标签（00:00 … 23:00）
  static final List<String> hourLabels = [
    for (var hour = startHour; hour < endHour; hour++)
      '${hour.toString().padLeft(2, '0')}:00',
  ];

  /// 将分钟数格式化为 HH:mm
  static String formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  /// 像素 Y 对齐到 snapMinutes
  static double snapPixels(double pixels) {
    final minutes = pixels / hourHeight * 60;
    final snapped = (minutes / snapMinutes).round() * snapMinutes;
    return snapped / 60 * hourHeight;
  }

  /// 将局部 Y 坐标转为对齐后的分钟数
  static int snapMinutesFromLocalDy(double localDy) {
    final rawMinutes = localDy / hourHeight * 60;
    final snapped = (rawMinutes / snapMinutes).round() * snapMinutes;
    return snapped.clamp(0, dayMinutes - snapMinutes);
  }

  /// 分钟数对应的网格 top
  static double topFromMinutes(int minutes) => minutes / 60 * hourHeight;
}
