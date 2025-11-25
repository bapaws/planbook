import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/icon/cubit/settings_icon_cubit.dart';
import 'package:flutter_planbook/settings/icon/model/app_icons.dart';

@RoutePage()
class SettingsIconPage extends StatelessWidget {
  const SettingsIconPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsIconCubit()..onRequested(),
      child: const _SettingsIconPage(),
    );
  }
}

class _SettingsIconPage extends StatelessWidget {
  const _SettingsIconPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(
          '👑 ${l10n.appIcon}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: const CupertinoNavigationBarBackButton(),
      ),
      body: BlocBuilder<SettingsIconCubit, SettingsIconState>(
        builder: (context, state) {
          return ListView(
            children: [
              for (final icon in AppIcons.values) ...[
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onPressed: () {
                    if (context.read<AppPurchasesBloc>().isPremium) {
                      context.read<SettingsIconCubit>().onIconChanged(icon);
                    } else {}
                  },
                  child: Row(
                    children: [
                      Container(
                        width: kToolbarHeight,
                        height: kToolbarHeight,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.outlineVariant,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          theme.brightness == Brightness.light
                              ? 'assets/logos/light/${icon.iconName}.png'
                              : 'assets/logos/dark/${icon.iconName}.png',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        icon.getName(context),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (state.icon == icon)
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
                Divider(
                  color: theme.colorScheme.surfaceContainerHighest,
                  indent: kToolbarHeight + 32,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
