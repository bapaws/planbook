import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/view/app_text_field.dart';
import 'package:flutter_planbook/core/view/sign_button.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/sign/home/cubit/sign_home_cubit.dart';
import 'package:flutter_planbook/sign/in/cubit/sign_in_cubit.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignInCodePage extends StatefulWidget {
  const SignInCodePage({this.status, super.key});

  final SignHomeStatus? status;

  @override
  State<SignInCodePage> createState() => _SignInCodePageState();
}

class _SignInCodePageState extends State<SignInCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _canSendCode = true;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    final l10n = context.l10n;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      Fluttertoast.showToast(
        msg: l10n.phoneNumberMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
      );
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone) &&
        !EmailValidator.validate(phone)) {
      Fluttertoast.showToast(
        msg: l10n.phoneNumberMessageInvalid,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
      );
      return;
    }

    context.read<SignInCubit>().sendCode(phone: phone);
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<SignInCubit>().signInWithCode(
        phone: _phoneController.text.trim(),
        code: _codeController.text.trim(),
      );
    }
  }

  void _startCountdown() {
    setState(() {
      _canSendCode = false;
      _countdown = 60;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

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
    final theme = Theme.of(context);

    final status = widget.status;
    return BlocListener<SignInCubit, SignInState>(
      listener: (context, state) {
        if (state is SignInSuccess) {
          // 登录成功，导航到主页
          final isPremium = context.read<AppPurchasesBloc>().state.isPremium;
          print('isPremium: $isPremium');
          context.router.replaceAll([
            const RootHomeRoute(),
            if (!isPremium) const AppPurchasesRoute(),
          ]);
        } else if (state is SignInFailure) {
          Fluttertoast.showToast(
            msg: state.message,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black,
          );
        } else if (state is CodeSentSuccess) {
          // 验证码发送成功
          Fluttertoast.showToast(
            msg: l10n.codeSentSuccess,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black,
          );
          _startCountdown();
        } else if (state is CodeSentFailure) {
          if (kDebugMode) {
            print('state.message: ${state.message}');
          }
          // 验证码发送失败
          Fluttertoast.showToast(
            msg: state.message,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black,
          );
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  l10n.loginOrRegister,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 切换登录方式
                CupertinoButton(
                  onPressed: () {
                    context.read<SignHomeCubit>().backToWelcome();
                  },
                  child: Text(
                    l10n.back,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 手机号输入框
            AppTextField(
              hintText: switch (status) {
                SignHomeStatus.signInWithEmail => l10n.email,
                SignHomeStatus.signInWithPhone => l10n.phoneNumber,
                _ => l10n.phoneNumberOrEmail,
              },
              controller: _phoneController,
              textInputAction: TextInputAction.next,
              autofocus: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.phoneNumberMessage;
                }
                if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value) &&
                    !EmailValidator.validate(value)) {
                  return switch (status) {
                    SignHomeStatus.signInWithEmail => l10n.emailMessageInvalid,
                    SignHomeStatus.signInWithPhone =>
                      l10n.phoneNumberMessageInvalid,
                    _ => l10n.phoneNumberOrEmailMessageInvalid,
                  };
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 验证码输入框和发送按钮
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    hintText: l10n.verificationCode,
                    keyboardType: TextInputType.number,
                    controller: _codeController,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.verificationCodeMessage;
                      }
                      if (value.length != 6 && value.length != 8) {
                        return l10n.verificationCodeMessageInvalid;
                      }
                      return null;
                    },
                    onSubmitted: (value) => _handleSignIn(),
                  ),
                ),
                const SizedBox(width: 12),
                BlocBuilder<SignInCubit, SignInState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: 100,
                      child: SignButton(
                        // height: 48,
                        text: _canSendCode ? l10n.sendCode : '${_countdown}s',
                        onPressed: (_canSendCode && state is! CodeSending)
                            ? _handleSendCode
                            : () {},
                        isLoading: state is CodeSending,
                        style: SignButtonStyle.outlined,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 登录按钮
            BlocBuilder<SignInCubit, SignInState>(
              builder: (context, state) {
                return SignButton(
                  text: l10n.loginOrRegister,
                  style: SignButtonStyle.filled,
                  onPressed: _handleSignIn,
                  isLoading: state is SignInLoading,
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
