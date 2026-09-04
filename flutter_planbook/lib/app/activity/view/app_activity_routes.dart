import 'package:app_hub/app_hub.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AppActivityListPage extends StatelessWidget {
  const AppActivityListPage({super.key});

  @override
  Widget build(BuildContext context) => const AppHubActivitiesPage();
}

@RoutePage()
class AppActivityPage extends StatelessWidget {
  const AppActivityPage({
    @PathParam('activityId') required this.activityId,
    super.key,
  });

  final int activityId;

  @override
  Widget build(BuildContext context) {
    return _CampaignLookup(
      activityId: activityId,
      builder: (campaign) => AppHubCampaignPage(campaign: campaign),
    );
  }
}

@RoutePage()
class AppActivityRedeemListPage extends StatelessWidget {
  const AppActivityRedeemListPage({super.key});

  @override
  Widget build(BuildContext context) => const AppHubStatusListPage();
}

@RoutePage()
class AppActivityRedeemPage extends StatelessWidget {
  const AppActivityRedeemPage({
    @PathParam('activityId') required this.activityId,
    super.key,
  });

  final int activityId;

  @override
  Widget build(BuildContext context) {
    return _CampaignLookup(
      activityId: activityId,
      builder: (campaign) => AppHubSubmitPage(campaign: campaign),
    );
  }
}

class _CampaignLookup extends StatelessWidget {
  const _CampaignLookup({required this.activityId, required this.builder});

  final int activityId;
  final Widget Function(CampaignInfo campaign) builder;

  @override
  Widget build(BuildContext context) {
    final session = AppHubSession.maybeOf(context);
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        if (session.loading && session.campaigns.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final campaign = session.campaignByLegacyId(activityId);
        if (campaign == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Activity not found')),
          );
        }
        return builder(campaign);
      },
    );
  }
}
