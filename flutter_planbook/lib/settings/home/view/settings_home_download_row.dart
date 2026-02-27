import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsHomeDownloadRow extends StatelessWidget {
  const SettingsHomeDownloadRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocConsumer<AppBloc, AppState>(
      listenWhen: (prev, curr) =>
          prev.apkDownloadStatus != curr.apkDownloadStatus,
      listener: (context, state) {
        if (state.apkDownloadStatus == AppApkDownloadStatus.installError &&
            state.apkDownloadErrorMessage != null) {
          EasyLoading.showError(state.apkDownloadErrorMessage!);
        }
      },
      buildWhen: (prev, curr) =>
          prev.apkVersion != curr.apkVersion ||
          prev.apkDownloadStatus != curr.apkDownloadStatus ||
          prev.apkDownloadProgress != curr.apkDownloadProgress,
      builder: (context, state) {
        if (state.apkVersion == null || !state.apkHasNewVersion) {
          return const SizedBox.shrink();
        }

        final isDownloading =
            state.apkDownloadStatus == AppApkDownloadStatus.downloading;
        return SettingsRow(
          leading: const Icon(
            FontAwesomeIcons.solidCircleDown,
            color: Colors.blue,
            size: 20,
          ),
          title: Text(
            isDownloading ? l10n.apkDownloadUpdating : l10n.apkDownloadUpdate,
          ),
          additionalInfo: Text(state.apkVersion ?? ''),
          trailing: isDownloading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    value: state.apkDownloadProgress,
                    strokeWidth: 3,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                )
              : const CupertinoListTileChevron(),
          onPressed: isDownloading
              ? null
              : () {
                  context.read<AppBloc>().add(
                        AppApkDownloadRequested(l10n: context.l10n),
                      );
                },
        );
      },
    );
  }
}
