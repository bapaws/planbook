import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/activity/model/app_activity_notice.dart';
import 'package:flutter_planbook/app/activity/view/app_activity_notice_navigation.dart';

/// AppBar 紧凑活动通知入口。
class AppActivityNoticeAppBarAction extends StatelessWidget {
  const AppActivityNoticeAppBarAction({
    required this.notice,
    super.key,
  });

  final AppActivityNotice notice;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => openAppActivityNotice(context, notice),
      child: Text(notice.activity.emoji).flash(
        infinite: true,
        duration: const Duration(seconds: 2),
        delay: const Duration(seconds: 1),
      ),
    );
  }
}

/// 任务页 AppBar 通知入口（仅一条：新活动或审核通过）。
class AppActivityNoticeAppBarActions extends StatelessWidget {
  const AppActivityNoticeAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppActivityBloc, AppActivityState, AppActivityNotice?>(
      selector: (state) => state.appBarNotice,
      builder: (context, notice) {
        if (notice == null) return const SizedBox.shrink();
        return AppActivityNoticeAppBarAction(notice: notice);
      },
    );
  }
}
