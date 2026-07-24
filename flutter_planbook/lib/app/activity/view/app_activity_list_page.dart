import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/activity/model/app_activity_notice.dart';
import 'package:flutter_planbook/app/activity/view/app_activity_notice_navigation.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class AppActivityListPage extends StatelessWidget {
  const AppActivityListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: const NavigationBarBackButton(),
        title: Text(context.l10n.rewardActivities),
        actions: const [
          _RedeemPromoCodeAction(),
        ],
      ),
      body: BlocBuilder<AppActivityBloc, AppActivityState>(
        builder: (context, state) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: state.activities.length,
            itemBuilder: (context, index) {
              final activity = state.activities[index];
              return SettingsRow(
                leading: Text(
                  activity.emoji,
                  style: textTheme.titleLarge,
                ),
                title: Text(
                  activity.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () {
                  context.router.push(AppActivityRoute(activity: activity));
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// 右上角兑换码入口（仅已收到兑换码时显示）。
class _RedeemPromoCodeAction extends StatelessWidget {
  const _RedeemPromoCodeAction();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppActivityBloc, AppActivityState, AppActivityNotice?>(
      selector: (state) => state.redeemApprovedNotice,
      builder: (context, notice) {
        if (notice == null) return const SizedBox.shrink();

        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: () => openAppActivityNotice(context, notice),
          child: Text(context.l10n.redeemPromoCode),
        );
      },
    );
  }
}
