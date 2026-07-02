import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/redeem/bloc/app_activity_redeem_bloc.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/image_picker.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class AppActivityRedeemPage extends StatelessWidget {
  const AppActivityRedeemPage({
    required this.activity,
    super.key,
  });

  final ActivityMessageEntity activity;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AppActivityRedeemBloc()..add(const AppActivityRedeemStarted()),
      child: _AppActivityRedeemView(activity: activity),
    );
  }
}

class _AppActivityRedeemView extends StatelessWidget {
  const _AppActivityRedeemView({required this.activity});

  final ActivityMessageEntity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: const NavigationBarBackButton(),
        centerTitle: false,
      ),
      body: SafeArea(
        child: BlocBuilder<AppActivityRedeemBloc, AppActivityRedeemState>(
          builder: (context, state) => _buildBody(
            context,
            state: state,
            l10n: l10n,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required AppActivityRedeemState state,
    required AppLocalizations l10n,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    if (state.phase == AppActivityRedeemPhase.unsupported) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.redeemUnsupported,
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Text(
                  '${activity.emoji} ${activity.title}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _StatusBanner(state: state),
                if (state.phase == AppActivityRedeemPhase.initial ||
                    state.phase == AppActivityRedeemPhase.rejected) ...[
                  Text(
                    l10n.redeemSelectImages,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  _ImagePreviewGrid(paths: state.imagePaths),
                ],
                if (state.phase == AppActivityRedeemPhase.approved &&
                    state.code != null)
                  _ApprovedCard(code: state.code!),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: _BottomActions(state: state),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final AppActivityRedeemState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final String message;
    final Color bg;
    switch (state.phase) {
      case AppActivityRedeemPhase.pending:
        message = l10n.redeemPending;
        bg = colorScheme.primaryContainer;
      case AppActivityRedeemPhase.approved:
        message = l10n.redeemApproved;
        bg = colorScheme.tertiaryContainer;
      case AppActivityRedeemPhase.rejected:
        message = (state.rejectReason?.isNotEmpty ?? false)
            ? state.rejectReason!
            : l10n.redeemRejected;
        bg = colorScheme.errorContainer;
      case AppActivityRedeemPhase.alreadyRewarded:
        message = l10n.redeemAlreadyRewarded;
        bg = colorScheme.surfaceContainerHighest;
      case AppActivityRedeemPhase.rateLimited:
        message = l10n.redeemRateLimited;
        bg = colorScheme.errorContainer;
      case AppActivityRedeemPhase.initial:
      case AppActivityRedeemPhase.unsupported:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: textTheme.bodyMedium,
      ),
    );
  }
}

class _ImagePreviewGrid extends StatelessWidget {
  const _ImagePreviewGrid({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Icon(
          CupertinoIcons.photo_on_rectangle,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(paths[index]),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}

class _ApprovedCard extends StatelessWidget {
  const _ApprovedCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(l10n.redeemOfferCode, style: textTheme.labelLarge),
          SelectableText(
            code,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              await Fluttertoast.showToast(
                msg: l10n.copy,
                gravity: ToastGravity.CENTER,
              );
            },
            child: Text(l10n.copy),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.state});

  final AppActivityRedeemState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLoading = state.status == PageStatus.loading;

    if (state.canRedeem) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          borderRadius: BorderRadius.circular(16),
          onPressed: isLoading
              ? null
              : () {
                  context.read<AppActivityRedeemBloc>().add(
                    const AppActivityRedeemRedeemTapped(),
                  );
                },
          child: Text(l10n.redeemNow),
        ),
      );
    }

    if (state.phase == AppActivityRedeemPhase.pending ||
        state.phase == AppActivityRedeemPhase.alreadyRewarded) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          borderRadius: BorderRadius.circular(16),
          onPressed: isLoading
              ? null
              : () {
                  context.read<AppActivityRedeemBloc>().add(
                    const AppActivityRedeemStatusRefreshed(),
                  );
                },
          child: isLoading
              ? const CupertinoActivityIndicator()
              : Text(l10n.redeemRefreshStatus),
        ),
      );
    }

    if (state.phase == AppActivityRedeemPhase.rejected) {
      return Row(
        spacing: 12,
        children: [
          Expanded(
            child: CupertinoButton.tinted(
              borderRadius: BorderRadius.circular(16),
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<AppActivityRedeemBloc>().add(
                        const AppActivityRedeemResetTapped(),
                      );
                    },
              child: Text(l10n.redeemSelectImages),
            ),
          ),
          Expanded(
            child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(16),
              onPressed: isLoading || state.imagePaths.isEmpty
                  ? null
                  : () async {
                      final paths = await showRedeemImagePicker(context);
                      if (paths == null || !context.mounted) return;
                      context.read<AppActivityRedeemBloc>().add(
                        AppActivityRedeemImagesPicked(paths),
                      );
                    },
              child: Text(l10n.submitReviewScreenshot),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        CupertinoButton.tinted(
          borderRadius: BorderRadius.circular(16),
          onPressed: isLoading
              ? null
              : () async {
                  final paths = await showRedeemImagePicker(context);
                  if (paths == null || !context.mounted) return;
                  context.read<AppActivityRedeemBloc>().add(
                    AppActivityRedeemImagesPicked(paths),
                  );
                },
          child: Text(l10n.redeemSelectImages),
        ),
        CupertinoButton.filled(
          borderRadius: BorderRadius.circular(16),
          onPressed: state.canSubmit && !isLoading
              ? () {
                  context.read<AppActivityRedeemBloc>().add(
                    const AppActivityRedeemSubmitted(),
                  );
                }
              : null,
          child: isLoading
              ? const CupertinoActivityIndicator()
              : Text(l10n.submitReviewScreenshot),
        ),
      ],
    );
  }
}
