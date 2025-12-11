import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/core/view/app_text_field.dart';
import 'package:flutter_planbook/core/view/sign_button.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/sign/home/cubit/sign_home_cubit.dart';
import 'package:flutter_planbook/sign/up/cubit/sign_up_cubit.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请同意条款和条件'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<SignUpCubit>().signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<SignUpCubit, SignUpState>(
      listener: (context, state) {
        if (state is SignUpSuccess) {
          // 注册成功，显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('注册成功！请检查您的邮箱以验证账号。'),
              backgroundColor: Colors.green,
            ),
          );
          // 返回登录页面
          context.router.pop();
        } else if (state is SignUpFailure) {
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
              l10n.welcome,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            // 姓名输入框
            AppTextField(
              hintText: l10n.name,
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入姓名';
                }
                return null;
              },
            ),

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

            // 密码输入框
            AppTextField(
              hintText: l10n.password,
              obscureText: _obscurePassword,
              controller: _passwordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 6) {
                  return '密码长度至少6位';
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
            ),

            // 确认密码输入框
            AppTextField(
              hintText: l10n.confirmPassword,
              obscureText: _obscureConfirmPassword,
              controller: _confirmPasswordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请确认密码';
                }
                if (value != _passwordController.text) {
                  return '密码不匹配';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),

            // 同意条款选项
            Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  activeColor: Colors.black,
                ),
                Expanded(
                  child: Text(
                    l10n.agreeToTerms,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 注册按钮
            BlocBuilder<SignUpCubit, SignUpState>(
              builder: (context, state) {
                return SignButton(
                  text: l10n.signUp,
                  onPressed: _handleSignUp,
                  isLoading: state is SignUpLoading,
                );
              },
            ),

            // 登录链接
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.alreadyHaveAccount,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // 返回登录页面
                      context.read<SignHomeCubit>().signInWithPhone();
                    },
                    child: Text(
                      l10n.signInHere,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
