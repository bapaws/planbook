import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_text_field.dart';
import 'package:flutter_planbook/core/view/sign_button.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/mine/phone/cubit/mine_phone_cubit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class MinePhonePage extends StatelessWidget {
  const MinePhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) => MinePhoneCubit(
        usersRepository: context.read(),
        l10n: l10n,
      ),
      child: const _MinePhonePage(),
    );
  }
}

class _MinePhonePage extends StatefulWidget {
  const _MinePhonePage();

  @override
  State<_MinePhonePage> createState() => _MinePhonePageState();
}

class _MinePhonePageState extends State<_MinePhonePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _canSendCode = true;
  int _countdown = 60;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    if (_phoneController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: '请输入手机号',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
      );
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(_phoneController.text.trim())) {
      Fluttertoast.showToast(
        msg: '请输入有效的手机号',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
      );
      return;
    }

    context.read<MinePhoneCubit>().sendCode(_phoneController.text.trim());
    _startCountdown();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<MinePhoneCubit>().verifyCode(
        _phoneController.text.trim(),
        _codeController.text.trim(),
      );
    }
  }

  void _startCountdown() {
    setState(() {
      _canSendCode = false;
      _countdown = 60;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
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

    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(l10n.changePhone),
        leading: const NavigationBarBackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 手机号输入框
              AppTextField(
                hintText: l10n.phoneNumber,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                textInputAction: TextInputAction.next,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.phoneNumberMessage;
                  }
                  if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                    return l10n.phoneNumberMessageInvalid;
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
                          return '请输入验证码';
                        }
                        if (value.length != 6) {
                          return '验证码为6位数字';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  BlocBuilder<MinePhoneCubit, MinePhoneState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: 100,
                        child: SignButton(
                          // height: 48,
                          text: _canSendCode ? l10n.sendCode : '${_countdown}s',
                          onPressed:
                              (_canSendCode &&
                                  state.status == PageStatus.initial)
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

              // 登录按钮
              BlocBuilder<MinePhoneCubit, MinePhoneState>(
                builder: (context, state) {
                  return SignButton(
                    text: l10n.save,
                    onPressed: _save,
                    style: SignButtonStyle.filled,
                    isLoading: state.status == PageStatus.loading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
