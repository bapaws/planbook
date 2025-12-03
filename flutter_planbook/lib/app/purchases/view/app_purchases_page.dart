import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/app/purchases/view/app_purchases_footer.dart';
import 'package:flutter_planbook/app/purchases/view/app_purchases_summary_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:in_app_review/in_app_review.dart';
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
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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
                    const AppPurchasesSummaryView(),
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
