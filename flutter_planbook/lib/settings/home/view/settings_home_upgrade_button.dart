import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:shimmer/shimmer.dart';

class SettingsHomeUpgradeButton extends StatelessWidget {
  const SettingsHomeUpgradeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onPressed: () {
        if (context.read<AppPurchasesBloc>().state.isLifetime) {
          return;
        }
        context.router.push(const AppPurchasesRoute());
      },
      child: Shimmer(
        gradient: const LinearGradient(
          colors: [
            Colors.red,
            Colors.blue,
            Colors.red,
          ],
        ),
        child: BlocSelector<AppPurchasesBloc, AppPurchasesState, String?>(
          selector: (state) => state.activeProductId,
          builder: (context, activeProductId) {
            final storeProduct = context
                .read<AppPurchasesBloc>()
                .state
                .storeProducts
                .firstWhereOrNull(
                  (e) => e.id == activeProductId,
                );
            var title = storeProduct?.title;
            if (title == null && activeProductId != null) {
              title = context.l10n.unlockedPro;
            }
            return Text(
              title ?? context.l10n.upgrade,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
    );
  }
}
