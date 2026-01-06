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

class SignInPasswordPage extends StatefulWidget {
  const SignInPasswordPage({super.key});

  @override
  State<SignInPasswordPage> createState() => _SignInPasswordPageState();
}

class _SignInPasswordPageState extends State<SignInPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _phoneController.text = 'minchaozhang@163.com';
      _passwordController.text = 'VfP8Jce4pLKaWWc';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<SignInCubit>().signInWithPassword(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    }
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
          // 显示错误信息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  l10n.welcomeBack,
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
              autofocus: true,
              hintText: l10n.phoneNumberOrEmail,
              controller: _phoneController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.phoneNumberMessage;
                }
                if (!RegExp(
                  r'^1[3-9]\d{9}$|^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                ).hasMatch(value)) {
                  return l10n.phoneNumberMessageInvalid;
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 密码输入框
            AppTextField(
              hintText: l10n.password,
              obscureText: _obscurePassword,
              controller: _passwordController,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.passwordMessage;
                }
                if (value.length < 6) {
                  return l10n.passwordMessage;
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              onSubmitted: (value) => _handleSignIn(),
            ),

            const SizedBox(height: 24),

            // 登录按钮
            BlocBuilder<SignInCubit, SignInState>(
              builder: (context, state) {
                return SignButton(
                  text: l10n.signIn,
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
