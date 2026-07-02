import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/app_channel.dart';

/// 监听活动数据就绪后弹出 Alert，同一会话内同一活动只弹一次。
class AppActivityAlertListener extends StatefulWidget {
  const AppActivityAlertListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<AppActivityAlertListener> createState() =>
      _AppActivityAlertListenerState();
}

class _AppActivityAlertListenerState extends State<AppActivityAlertListener> {
  static final Set<int> _shownActivityIdsThisSession = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShowAlert(context.read<AppActivityBloc>().state);
    });
  }

  void _maybeShowAlert(AppActivityState state) {
    if (!AppChannel.isMain) return;
    if (!state.isReleasedVersion) return;

    final alert = state.alertNotice;
    if (alert == null) return;
    if (_shownActivityIdsThisSession.contains(alert.activity.id)) return;

    _shownActivityIdsThisSession.add(alert.activity.id);
    context.router.push(AppActivityAlertRoute(activity: alert.activity));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppActivityBloc, AppActivityState>(
      listenWhen: (previous, current) =>
          previous.alertNotice != current.alertNotice ||
          previous.isReleasedVersion != current.isReleasedVersion,
      listener: (context, state) => _maybeShowAlert(state),
      child: widget.child,
    );
  }
}
