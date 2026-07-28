import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/core/view/app_pro_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

/// 时间块视图演示模式顶部提示：说明为演示数据，点击跳转会员页
class AppDemoBanner extends StatelessWidget {
  const AppDemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.router.push(const AppPurchasesRoute()),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsetsDirectional.only(
          start: 8,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: context.pinkColorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.pinkColorScheme.errorContainer,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.timeBlockDemoBannerTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: context.pinkColorScheme.primary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.blueColorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppProView(
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
