import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/core/view/app_text_field.dart';
import 'package:flutter_planbook/core/view/sign_button.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/mine/email/cubit/mine_email_cubit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class MineEmailPage extends StatelessWidget {
  const MineEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) => MineEmailCubit(
        usersRepository: context.read(),
        l10n: l10n,
      ),
      child: const _MineEmailPage(),
    );
  }
}

class _MineEmailPage extends StatefulWidget {
  const _MineEmailPage();

  @override
  State<_MineEmailPage> createState() => _MineEmailPageState();
}

class _MineEmailPageState extends State<_MineEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _canSendCode = true;
  int _countdown = 60;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    if (_emailController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: context.l10n.emailMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    }

    if (!EmailValidator.validate(_emailController.text.trim())) {
      Fluttertoast.showToast(
        msg: context.l10n.emailMessageInvalid,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    }

    context.read<MineEmailCubit>().sendCode(_emailController.text.trim());
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<MineEmailCubit>().verifyCode(
        _emailController.text.trim(),
        _codeController.text.trim(),
      );
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _canSendCode = false;
      _countdown = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        setState(() {
          _canSendCode = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<MineEmailCubit, MineEmailState>(
      listenWhen: (previous, current) =>
          (!previous.isSent && current.isSent) ||
          current.status == PageStatus.success,
      listener: (context, state) {
        if (state.status == PageStatus.success) {
          context.router.maybePop();
          return;
        }
        if (state.isSent) {
          _startCountdown();
        }
      },
      child: AppScaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: Text(l10n.changeEmail),
          leading: const NavigationBarBackButton(),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 邮箱输入框
                AppTextField(
                  hintText: l10n.email,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.emailMessage;
                    }
                    if (!EmailValidator.validate(value)) {
                      return l10n.emailMessageInvalid;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 验证码输入框和发送按钮
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        hintText: l10n.verificationCode,
                        keyboardType: TextInputType.number,
                        controller: _codeController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.l10n.verificationCodeMessage;
                          }
                          if (value.length != 6) {
                            return context.l10n.verificationCodeMessageInvalid;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    BlocBuilder<MineEmailCubit, MineEmailState>(
                      builder: (context, state) {
                        return SizedBox(
                          width: 100,
                          child: SignButton(
                            text: _canSendCode
                                ? l10n.sendCode
                                : '${_countdown}s',
                            onPressed:
                                (_canSendCode &&
                                    state.status != PageStatus.loading)
                                ? _handleSendCode
                                : () {},
                            isLoading: state.status == PageStatus.loading,
                            style: SignButtonStyle.outlined,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 保存按钮
                BlocBuilder<MineEmailCubit, MineEmailState>(
                  builder: (context, state) {
                    return SignButton(
                      text: l10n.save,
                      onPressed: _save,
                      isLoading: state.status == PageStatus.loading,
                      style: SignButtonStyle.filled,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
