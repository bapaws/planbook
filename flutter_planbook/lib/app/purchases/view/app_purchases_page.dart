import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/purchases/model/app_pro_features.dart';
import 'package:flutter_planbook/app/purchases/view/app_purchases_footer.dart';
import 'package:flutter_planbook/core/purchases/app_purchases.dart';
import 'package:flutter_planbook/core/view/app_pro_view.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:url_launcher/url_launcher_string.dart';

@RoutePage()
class AppPurchasesPage extends StatefulWidget {
  const AppPurchasesPage({super.key});

  @override
  State<AppPurchasesPage> createState() => _AppPurchasesPageState();
}

class _AppPurchasesPageState extends State<AppPurchasesPage> {
  @override
  void initState() {
    super.initState();
    context.read<AppPurchasesBloc>().add(const AppPurchasesRequested());

    // _requestReview();
  }

  Future<void> _requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AppPurchasesBloc, AppPurchasesState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == PageStatus.loading) {
              EasyLoading.show();
            } else if (EasyLoading.isShow && !state.entitlementJustGranted) {
              // 成功提示由下方 listener 接管，避免先 dismiss 再闪一下
              EasyLoading.dismiss();
            }
          },
        ),
        // 购买/恢复成功：提示后再关页（已是会员时 isPremium 不会翻转，不能依赖它）
        BlocListener<AppPurchasesBloc, AppPurchasesState>(
          listenWhen: (previous, current) =>
              !previous.entitlementJustGranted &&
              current.entitlementJustGranted,
          listener: (context, state) async {
            await EasyLoading.showSuccess(
              AppLocalizations.of(context).purchaseSuccessHint,
            );
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        // 支付失败/取消必须给用户反馈：区分于成功，并提示已扣款可走恢复
        BlocListener<AppPurchasesBloc, AppPurchasesState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == PageStatus.failure,
          listener: (context, state) {
            EasyLoading.showError(
              state.isRestoreFailure
                  ? AppLocalizations.of(context).restorePurchasesFailedHint
                  : AppLocalizations.of(context).purchaseFailedHint,
              duration: const Duration(seconds: 4),
            );
          },
        ),
      ],
      child: const _AppPurchasesPage(),
    );
  }
}

class _AppPurchasesPage extends StatelessWidget {
  const _AppPurchasesPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: const NavigationBarBackButton(),
        title: AppProView(
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.restore),
            onPressed: () {
              context.read<AppPurchasesBloc>().add(
                const AppPurchasesRestored(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AppPurchasesBloc, AppPurchasesState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  children: [
                    SvgPicture.asset(
                      'assets/images/pro-bg.svg',
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: kMinInteractiveDimension,
                      ),
                      child: Text(
                        l10n.proFeatures,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Divider(
                      height: 24,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: SizedBox.square()),
                        Expanded(
                          child: Center(
                            child: Text(
                              l10n.basic,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              l10n.pro,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final feature in AppProFeatures.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                feature.getTitle(context),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  feature.getBasicText(context),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  feature.getProTotalText(context),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoButton(
                          child: Text(
                            l10n.privacy,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                          onPressed: () {
                            launchUrlString(l10n.privacyAgreementUrl);
                          },
                        ),
                        const Text('|'),
                        CupertinoButton(
                          child: Text(
                            l10n.terms,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                          onPressed: () {
                            launchUrlString(l10n.userAgreementUrl);
                          },
                        ),
                        if (AppPurchases.instance.usesChinaPay) ...[
                          const Text('|'),
                          CupertinoButton(
                            onPressed: () {
                              launchUrlString(
                                'https://uxsyr9xrl46.feishu.cn/wiki/MBNrwTS1JijUdNkJWsKcTnu5nYe',
                              );
                            },
                            child: Text(
                              '会员协议',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.disabledColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // const SizedBox(height: kMinInteractiveDimension),
                  ],
                ),
              ),
              const AppPurchasesFooter(),
            ],
          );
        },
      ),
    );
  }
}
