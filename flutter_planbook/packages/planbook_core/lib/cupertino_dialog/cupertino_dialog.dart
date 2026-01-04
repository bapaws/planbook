import 'package:flutter/material.dart';
import 'package:planbook_core/cupertino_dialog/calendar_dismiss_behavior.dart';
import 'package:planbook_core/cupertino_dialog/cupertino_picker_overlay.dart';
import 'package:planbook_core/cupertino_dialog/picker_container_decoration.dart';

const String calendarPickerRouteName = 'CupertinoCalendarPicker';
const String calendarPickerBarrierLabel = 'CupertinoCalendarPickerBarrier';

void showCupertinoCalendarPicker(
  BuildContext context, {
  required RenderBox? widgetRenderBox,
  required Widget child,
  required double height,
  required double width,
  PickerContainerDecoration? containerDecoration,
  double horizontalSpacing = 15.0,
  double verticalSpacing = 15.0,
  Offset offset = const Offset(0, 10),
  Color barrierColor = Colors.transparent,
  bool useRootNavigator = true,
  CalendarDismissBehavior dismissBehavior =
      CalendarDismissBehavior.onOutsideTap,
}) {
  showGeneralDialog(
    context: context,
    barrierLabel: calendarPickerBarrierLabel,
    barrierColor: barrierColor,
    transitionDuration: Duration.zero,
    routeSettings: const RouteSettings(name: calendarPickerRouteName),
    useRootNavigator: useRootNavigator,
    transitionBuilder:
        (
          BuildContext _,
          Animation<double> __,
          Animation<double> ___,
          Widget child,
        ) {
          return child;
        },
    pageBuilder:
        (
          BuildContext _,
          Animation<double> __,
          Animation<double> ___,
        ) {
          return CupertinoPickerOverlay(
            containerDecoration: containerDecoration,
            widgetRenderBox: widgetRenderBox,
            height: height,
            width: width,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            offset: offset,
            outsideTapDismissable: dismissBehavior.hasOusideTapDismiss,
            child: child,
          );
        },
  );
}
