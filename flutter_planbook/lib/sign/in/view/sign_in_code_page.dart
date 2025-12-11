import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_text_field.dart';
import 'package:flutter_planbook/core/view/sign_button.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/sign/home/cubit/sign_home_cubit.dart';
import 'package:flutter_planbook/sign/in/cubit/sign_in_cubit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignInPhonePage extends StatefulWidget {
  const SignInPhonePage({super.key});

  @override
  State<SignInPhonePage> createState() => _SignInPhonePageState();
}

class _SignInPhonePageState extends State<SignInPhonePage> {
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
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      Fluttertoast.showToast(
        msg: '请输入手机号',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
      );
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone) &&
        !EmailValidator.validate(phone)) {
      Fluttertoast.showToast(
        msg: '请输入有效的手机号',
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
    return BlocListener<SignInCubit, SignInState>(
      listener: (context, state) {
        if (state is SignInSuccess) {
          // 登录成功，导航到主页
          context.router.replaceAll([const RootHomeRoute()]);
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
            msg: '验证码已发送',
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
                    context.read<SignHomeCubit>().signInWithPassword();
                  },
                  child: Row(
                    children: [
                      Text(
                        l10n.password,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Icon(
                        FontAwesomeIcons.arrowRightArrowLeft,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 手机号输入框
            AppTextField(
              hintText: l10n.phoneNumber,
              controller: _phoneController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入手机号';
                }
                if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value) &&
                    !EmailValidator.validate(value)) {
                  return '请输入有效的手机号';
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入验证码';
                      }
                      if (value.length != 6 && value.length != 8) {
                        return '验证码为6位数字';
                      }
                      return null;
                    },
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
