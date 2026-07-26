import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:jiffy/jiffy.dart';

/// 周视图按星期映射的配色（八宫格与列表共用）。
extension TaskWeekDayColorScheme on BuildContext {
  /// 返回 [day] 对应星期的 [ColorScheme]。
  ColorScheme colorSchemeForWeekDay(Jiffy day) {
    switch (day.dateTime.weekday) {
      case DateTime.monday:
        return greyColorScheme;
      case DateTime.tuesday:
        return indigoColorScheme;
      case DateTime.wednesday:
        return pinkColorScheme;
      case DateTime.thursday:
        return purpleColorScheme;
      case DateTime.friday:
        return blueColorScheme;
      case DateTime.saturday:
        return redColorScheme;
      case DateTime.sunday:
        return amberColorScheme;
      default:
        return brownColorScheme;
    }
  }
}
