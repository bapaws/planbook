import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/core/view/app_text_field.dart';
import 'package:flutter_planbook/core/view/sign_button.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/sign/home/cubit/sign_home_cubit.dart';
import 'package:flutter_planbook/sign/password/cubit/sign_password_cubit.dart';

class SignPasswordPage extends StatefulWidget {
  const SignPasswordPage({super.key});

  @override
  State<SignPasswordPage> createState() => _SignPasswordPageState();
}

class _SignPasswordPageState extends State<SignPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SignPasswordCubit>().resetPassword(
        email: _emailController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<SignPasswordCubit, SignPasswordState>(
      listener: (context, state) {
        if (state is SignPasswordSuccess) {
          // 重置密码成功，显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('重置密码链接已发送到您的邮箱，请检查邮箱并点击链接重置密码。'),
              backgroundColor: Colors.green,
            ),
          );
          // 返回登录页面
          context.router.pop();
        } else if (state is SignPasswordFailure) {
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
            Text(
              l10n.resetPassword,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 描述
            Text(
              l10n.resetPasswordDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),

            // 邮箱输入框
            AppTextField(
              hintText: l10n.email,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入邮箱';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return '请输入有效的邮箱地址';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 发送重置链接按钮
            BlocBuilder<SignPasswordCubit, SignPasswordState>(
              builder: (context, state) {
                return SignButton(
                  text: l10n.sendResetLink,
                  onPressed: _handleResetPassword,
                  isLoading: state is SignPasswordLoading,
                );
              },
            ),

            // 返回登录链接
            Center(
              child: TextButton(
                onPressed: () {
                  // 返回登录页面
                  context.read<SignHomeCubit>().signInWithPhone();
                },
                child: Text(
                  l10n.backToSignIn,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
