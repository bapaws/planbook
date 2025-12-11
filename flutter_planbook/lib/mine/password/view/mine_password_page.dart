import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/mine/password/cubit/mine_password_cubit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class MinePasswordPage extends StatelessWidget {
  const MinePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MinePasswordCubit(
        usersRepository: context.read(),
        l10n: context.l10n,
      ),
      child: BlocListener<MinePasswordCubit, MinePasswordState>(
        listener: (context, state) {
          if (state.status == PageStatus.success) {
            context.router.popTop();
          }
        },
        child: _UpdatePasswordPage(),
      ),
    );
  }
}

class _UpdatePasswordPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController comfirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<MinePasswordCubit>();
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(l10n.changePassword),
        leading: const NavigationBarBackButton(),
      ),
      body: BlocBuilder<MinePasswordCubit, MinePasswordState>(
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).viewPadding.top,
              16,
              MediaQuery.of(context).viewPadding.bottom,
            ),
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.passwordMessage,
                maxLines: 2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: passwordController,
                placeholder: l10n.password,
                autofocus: true,
                padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 16, 12),
                prefix: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    FontAwesomeIcons.lock,
                    size: 18,
                  ),
                ),
                obscureText: state.obscureText,
                clearButtonMode: OverlayVisibilityMode.editing,
                suffix: CupertinoButton(
                  onPressed: bloc.toggleObscureText,
                  child: state.obscureText
                      ? const Icon(CupertinoIcons.eye)
                      : const Icon(CupertinoIcons.eye_slash),
                ),
                decoration: getTextFieldDecoration(context),
                onChanged: bloc.onUpdatePassword,
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: comfirmPasswordController,
                placeholder: l10n.comfirmPassword,
                autofocus: true,
                padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 16, 12),
                prefix: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    FontAwesomeIcons.lock,
                    size: 18,
                  ),
                ),
                obscureText: state.comfirmObscureText,
                clearButtonMode: OverlayVisibilityMode.editing,
                suffix: CupertinoButton(
                  onPressed: bloc.toggleComfirmObscureText,
                  child: state.comfirmObscureText
                      ? const Icon(CupertinoIcons.eye)
                      : const Icon(CupertinoIcons.eye_slash),
                ),
                decoration: getTextFieldDecoration(context),
                onChanged: bloc.onUpdateComfirmPassword,
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: Durations.short4,
                child: state.status == PageStatus.loading
                    ? const SizedBox(
                        width: double.infinity,
                        height: kMinInteractiveDimension,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : CupertinoButton.filled(
                        padding: EdgeInsets.zero,
                        minSize: kMinInteractiveDimension,
                        borderRadius: BorderRadius.circular(
                          kMinInteractiveDimension,
                        ),
                        onPressed: state.isValid
                            ? () {
                                onSubmited(context);
                              }
                            : null,
                        child: SizedBox(
                          width: double.infinity,
                          child: Center(child: Text(l10n.save)),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  BoxDecoration getTextFieldDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      color: theme.colorScheme.surfaceContainerLowest,
    );
  }

  Future<void> onSubmited(BuildContext context) async {
    final error = await context.read<MinePasswordCubit>().onSubmited();
    if (error != null) {
      await Fluttertoast.showToast(msg: error);
    }
  }
}
