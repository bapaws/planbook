import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/core/model/user_gender.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/mine/profile/cubit/mine_profile_cubit.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:pull_down_button/pull_down_button.dart';

@RoutePage()
class MineProfilePage extends StatelessWidget {
  const MineProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MineProfileCubit(
        usersRepository: context.read(),
        assetsRepository: context.read(),
      ),
      child: BlocListener<MineProfileCubit, MineProfileState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == PageStatus.loading) {
            EasyLoading.show(maskType: EasyLoadingMaskType.clear);
          } else if (EasyLoading.isShow) {
            EasyLoading.dismiss();
          }
        },
        child: const _MineProfilePage(),
      ),
    );
  }
}

class _MineProfilePage extends StatelessWidget {
  const _MineProfilePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: const NavigationBarBackButton(),
        actions: [
          PullDownButton(
            buttonBuilder: (context, show) => CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: show,
              child: const Icon(FontAwesomeIcons.ellipsis),
            ),
            itemBuilder: (context) => [
              PullDownMenuItem(
                icon: FontAwesomeIcons.trash,
                title: context.l10n.deleteAccount,
                isDestructive: true,
                onTap: () {
                  context.router.push(const MineDeleteRoute());
                },
              ),
            ],
          ),
        ],
      ),
      body: BlocSelector<AppBloc, AppState, UserEntity?>(
        selector: (state) => state.user,
        builder: (context, user) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      SettingsRow(
                        leading: const Icon(
                          FontAwesomeIcons.fingerprint,
                          color: Colors.purple,
                          size: 18,
                        ),
                        title: Text(context.l10n.userId),
                        additionalInfo: Text(
                          user?.maskedId ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: user?.id == null
                              ? null
                              : () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: user!.id),
                                  );
                                  if (!context.mounted) return;
                                  unawaited(
                                    Fluttertoast.showToast(
                                      msg: context.l10n.userIdCopySuccess,
                                      gravity: ToastGravity.CENTER,
                                    ),
                                  );
                                },
                          child: Icon(
                            CupertinoIcons.doc_on_doc,
                            size: 20,
                            color: user?.id == null
                                ? theme.colorScheme.outline.withValues(
                                    alpha: 0.4,
                                  )
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      SettingsRow(
                        leading: const Icon(
                          FontAwesomeIcons.phone,
                          color: Colors.green,
                          size: 18,
                        ),
                        title: Text(context.l10n.phoneNumber),
                        additionalInfo: Text(
                          user?.maskedPhone ?? context.l10n.bind,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        trailing: _buildCopyButton(
                          context,
                          value: user?.phone,
                          successMessage: context.l10n.phoneCopied,
                        ),
                        onPressed: () =>
                            context.router.push(const MinePhoneRoute()),
                      ),
                      SettingsRow(
                        leading: const Icon(
                          FontAwesomeIcons.solidEnvelope,
                          color: Colors.blue,
                          size: 18,
                        ),
                        title: Text(context.l10n.email),
                        additionalInfo: Text(
                          _emailDisplay(context, user),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        trailing: _buildCopyButton(
                          context,
                          value: _isWeChatEmail(user?.email)
                              ? null
                              : user?.email,
                          successMessage: context.l10n.emailCopied,
                        ),
                        onPressed: () =>
                            context.router.push(const MineEmailRoute()),
                      ),
                      SettingsRow(
                        leading: const Icon(
                          FontAwesomeIcons.key,
                          color: Colors.orange,
                          size: 18,
                        ),
                        title: Text(context.l10n.password),
                        additionalInfo: Text(
                          context.l10n.changePassword,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        onPressed: () =>
                            context.router.push(const MinePasswordRoute()),
                      ),
                      SettingsRow(
                        leading: const Icon(
                          FontAwesomeIcons.weixin,
                          color: Color(0xFF07C160),
                          size: 18,
                        ),
                        title: Text(context.l10n.weChat),
                        additionalInfo: Text(
                          _isWeChatLinked(user)
                              ? context.l10n.weChatLinked
                              : context.l10n.bind,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        onPressed: () {
                          context.read<MineProfileCubit>().linkWeChat();
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: kMinInteractiveDimension,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(
                        kMinInteractiveDimension,
                      ),
                      color: theme.colorScheme.surfaceContainer,
                      child: Text(context.l10n.logout),
                      onPressed: () async {
                        await context.read<MineProfileCubit>().onLogout();
                        if (context.mounted) {
                          await context.router.replaceAll([
                            const SignHomeRoute(),
                          ]);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isWeChatLinked(UserEntity? user) {
    return user?.user.userMetadata?['provider'] == 'wechat';
  }

  bool _isWeChatEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return email.endsWith('@planbook.internal.bapaws.com');
  }

  String _emailDisplay(BuildContext context, UserEntity? user) {
    final email = user?.email;
    if (email == null || email.isEmpty || _isWeChatEmail(email)) {
      return context.l10n.bind;
    }
    return user?.maskedEmail ?? context.l10n.bind;
  }

  Widget _buildCopyButton(
    BuildContext context, {
    required String? value,
    required String successMessage,
  }) {
    final theme = Theme.of(context);
    if (value == null || value.isEmpty) {
      return const CupertinoListTileChevron();
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        unawaited(
          Fluttertoast.showToast(
            msg: successMessage,
            gravity: ToastGravity.CENTER,
          ),
        );
      },
      child: Icon(
        CupertinoIcons.doc_on_doc,
        size: 20,
        color: theme.colorScheme.primary,
      ),
    );
  }

  void showBirthdayPicker(BuildContext context) {
    final cubit = context.read<MineProfileCubit>();
    final state = cubit.state;
    final theme = Theme.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height:
            MediaQuery.of(context).padding.bottom +
            216 +
            kMinInteractiveDimension,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  minimumSize: const Size(
                    kMinInteractiveDimension,
                    kMinInteractiveDimension,
                  ),
                  onPressed: () => context.router.pop(),
                  child: Text(context.l10n.cancel),
                ),
                CupertinoButton(
                  minimumSize: const Size(
                    kMinInteractiveDimension,
                    kMinInteractiveDimension,
                  ),
                  child: Text(context.l10n.save),
                  onPressed: () {
                    cubit.onBirthdaySubmitted();
                    context.router.pop();
                  },
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                initialDateTime: state.birthday,
                mode: CupertinoDatePickerMode.date,
                use24hFormat: true,
                showDayOfWeek: true,
                onDateTimeChanged: cubit.onBirthdayChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showGenderPicker(BuildContext context) {
    final cubit = context.read<MineProfileCubit>();
    final state = cubit.state;
    final theme = Theme.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height:
            MediaQuery.of(context).padding.bottom +
            216 +
            kMinInteractiveDimension,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  minimumSize: const Size(
                    kMinInteractiveDimension,
                    kMinInteractiveDimension,
                  ),
                  onPressed: () => context.router.pop(),
                  child: Text(context.l10n.cancel),
                ),
                CupertinoButton(
                  minimumSize: const Size(
                    kMinInteractiveDimension,
                    kMinInteractiveDimension,
                  ),
                  child: Text(context.l10n.save),
                  onPressed: () {
                    cubit.onGenderSubmitted();
                    context.router.pop();
                  },
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: UserGender.values.indexOf(
                    state.user?.gender ?? UserGender.unknown,
                  ),
                ),
                itemExtent: kMinInteractiveDimensionCupertino,
                onSelectedItemChanged: (index) {
                  cubit.onGenderChanged(UserGender.values[index]);
                },
                children: [
                  for (final gender in UserGender.values)
                    Center(child: Text(gender.getTitle(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
