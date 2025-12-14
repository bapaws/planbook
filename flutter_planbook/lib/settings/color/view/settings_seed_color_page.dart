import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.gr.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/model/app_seed_colors.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class SettingsSeedColorPage extends StatelessWidget {
  const SettingsSeedColorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(l10n.seedColor),
        leading: const NavigationBarBackButton(),
      ),
      body: BlocSelector<AppBloc, AppState, AppSeedColors>(
        selector: (state) => state.seedColor,
        builder: (context, seedColor) {
          final theme = Theme.of(context);
          return ListView(
            children: [
              for (final color in AppSeedColors.values) ...[
                SettingsRow(
                  leading: Icon(
                    Icons.palette,
                    color: color.color,
                  ),
                  title: Text(
                    color.getName(context),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: seedColor == color ? const Icon(Icons.check) : null,
                  onPressed: () {
                    if (!context.read<AppPurchasesBloc>().state.isPremium) {
                      context.router.push(const AppPurchasesRoute());
                      return;
                    }
                    context.read<AppBloc>().add(
                      AppSeedColorChanged(
                        seedColor: color,
                      ),
                    );
                  },
                ),
                Divider(
                  indent: 56,
                  height: 1,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
