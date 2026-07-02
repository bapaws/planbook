import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';

/// 四象限 header 长按进入自定义名称编辑页
class TaskPriorityHeaderLongPress extends StatelessWidget {
  const TaskPriorityHeaderLongPress({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        if (!context.read<AppPurchasesBloc>().isPremium) {
          context.router.push(const AppPurchasesRoute());
          return;
        }
        context.router.push(const SettingsQuadrantRoute());
      },
      child: child,
    );
  }
}
