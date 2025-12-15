import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/mine/delete/cubit/mine_delete_cubit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class MineDeletePage extends StatelessWidget {
  const MineDeletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MineDeleteCubit(
        usersRepository: context.read(),
        l10n: context.l10n,
      ),
      child: BlocListener<MineDeleteCubit, MineDeleteState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == PageStatus.success) {}
        },
        child: _MineDeletePage(),
      ),
    );
  }
}

class _MineDeletePage extends StatelessWidget {
  _MineDeletePage();

  late final confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(l10n.deleteAccount),
        leading: const NavigationBarBackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
          child: Column(
            children: [
              Text(
                '‼️ ${l10n.deleteAccountWarning}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  hintText: l10n.deleteAccountHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                onChanged: (value) {
                  context.read<MineDeleteCubit>().onConfirmTextChanged(value);
                },
              ),
              const Spacer(),
              BlocSelector<MineDeleteCubit, MineDeleteState, PageStatus>(
                selector: (state) => state.status,
                builder: (context, state) {
                  return AnimatedSwitcher(
                    duration: Durations.short4,
                    child: state.isLoading
                        ? const SizedBox(
                            height: kMinInteractiveDimensionCupertino,
                            width: kMinInteractiveDimensionCupertino,
                            child: CircularProgressIndicator(),
                          )
                        : CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 64),
                            borderRadius: BorderRadius.circular(
                              kMinInteractiveDimension,
                            ),
                            color: theme.colorScheme.surfaceContainer,
                            child: Text(
                              l10n.deleteAccount,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            onPressed: () {
                              showDeleteDialog(context);
                            },
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showDeleteDialog(BuildContext context) {
    if (confirmController.text != context.l10n.deleteAccount) {
      Fluttertoast.showToast(
        msg: context.l10n.deleteAccountHint,
        gravity: ToastGravity.CENTER,
      );
      return;
    }
    final l10n = context.l10n;
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              await context.read<MineDeleteCubit>().onDeleted();
              if (context.mounted) {
                context.router.popTop();
              }
            },
            isDestructiveAction: true,
            child: Text(l10n.deleteAccount),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
