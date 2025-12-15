import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/background/cubit/settings_background_cubit.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class SettingsBackgroundPage extends StatelessWidget {
  const SettingsBackgroundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) => SettingsBackgroundCubit(
        settingsRepository: context.read(),
        l10n: l10n,
      )..onRequested(),
      child: const _SettingsBackgroundPage(),
    );
  }
}

class _SettingsBackgroundPage extends StatelessWidget {
  const _SettingsBackgroundPage();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(context.l10n.background),
        leading: const NavigationBarBackButton(),
      ),
      body: BlocBuilder<SettingsBackgroundCubit, SettingsBackgroundState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          return ListView.builder(
            itemCount: state.assets.length,
            itemBuilder: (context, index) {
              final asset = state.assets[index];
              return SettingsRow(
                onPressed: () {
                  if (!context.read<AppPurchasesBloc>().isPremium) {
                    context.router.push(const AppPurchasesRoute());
                    return;
                  }
                  context.read<SettingsBackgroundCubit>().onAssetSelected(
                    asset.id,
                  );
                },
                title: Text(asset.name),
                trailing: Icon(
                  state.selectedAssetId == asset.id
                      ? FontAwesomeIcons.solidCircleCheck
                      : FontAwesomeIcons.circle,
                  color: state.selectedAssetId == asset.id
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  size: 20,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
