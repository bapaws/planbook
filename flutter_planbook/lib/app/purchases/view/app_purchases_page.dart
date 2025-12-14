import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/purchases/model/app_future_features.dart';
import 'package:flutter_planbook/app/purchases/model/app_pro_features.dart';
import 'package:flutter_planbook/app/purchases/view/app_purchases_footer.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:shimmer/shimmer.dart';
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
    context.read<AppPurchasesBloc>().add(const AppPurchasesPackageRequested());

    _requestReview();
  }

  Future<void> _requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppPurchasesBloc, AppPurchasesState>(
      listenWhen: (previous, current) =>
          previous.isPremium != current.isPremium,
      listener: (context, state) {
        if (state.isPremium) {
          Navigator.of(context).pop();
        }
      },
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
        title: Shimmer(
          gradient: const LinearGradient(
            colors: [
              Colors.red,
              Colors.blue,
              Colors.red,
            ],
          ),
          child: Text(
            'PRO',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          CupertinoButton(
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
                    Padding(
                      padding: const EdgeInsets.only(
                        top: kMinInteractiveDimension,
                      ),
                      child: Text(
                        l10n.futureFeatures,
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
                    for (final feature in AppFutureFeatures.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          // horizontal: 16,
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
                    Divider(
                      height: 36,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    Text(
                      l10n.aboutSubscription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Spacer(),
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
                        const Text('  |  '),
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
                        const Spacer(),
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
