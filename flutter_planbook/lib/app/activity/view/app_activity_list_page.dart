import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';

class AppActivityListPage extends StatelessWidget {
  const AppActivityListPage({super.key});

  static Route<void> route() {
    return CupertinoPageRoute<void>(
      builder: (context) => BlocProvider(
        create: (context) => AppActivityBloc(
          appActivityRepository: context.read(),
        )..add(const AppActivityFetchRequested()),
        child: const AppActivityListPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: const CupertinoNavigationBarBackButton(),
        title: Text(context.l10n.activities),
      ),
      body: BlocBuilder<AppActivityBloc, AppActivityState>(
        builder: (context, state) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
