import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/core/view/sign_button.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/sign/home/cubit/sign_home_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class SignWelcomePage extends StatelessWidget {
  const SignWelcomePage({super.key});

  Future<bool?> _showAgreementDialog(BuildContext context) async {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: _buildAgreementText(context),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(context.l10n.refuse),
          ),
          CupertinoDialogAction(
            onPressed: () {
              context.read<SignHomeCubit>().setIsAgreedToTerms(isAgreed: true);
              Navigator.of(context).pop(true);
            },
            child: Text(context.l10n.agreeToConditions),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignInWithCode(BuildContext context) async {
    final isAgreedToTerms = context.read<SignHomeCubit>().state.isAgreedToTerms;
    if (isAgreedToTerms) {
      context.read<SignHomeCubit>().signInWithCode();
    } else {
      final isAgreed = await _showAgreementDialog(context);
      if ((isAgreed ?? false) && context.mounted) {
        context.read<SignHomeCubit>().signInWithCode();
      }
    }
  }

  Future<void> _handleSignInWithPassword(BuildContext context) async {
    final isAgreedToTerms = context.read<SignHomeCubit>().state.isAgreedToTerms;
    if (isAgreedToTerms) {
      context.read<SignHomeCubit>().signInWithPassword();
    } else {
      final isAgreed = await _showAgreementDialog(context);
      if ((isAgreed ?? false) && context.mounted) {
        context.read<SignHomeCubit>().signInWithPassword();
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          l10n.welcome,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // 描述
        Text(
          l10n.welcomeDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),

        const SizedBox(height: 48),

        // 验证码登录按钮
        SignButton(
          text: l10n.usePhoneLogin,
          style: SignButtonStyle.filled,
          onPressed: () => _handleSignInWithCode(context),
        ),

        const SizedBox(height: 16),

        // 密码登录按钮
        SignButton(
          text: l10n.usePasswordLogin,
          onPressed: () => _handleSignInWithPassword(context),
          style: SignButtonStyle.outlined,
        ),

        const SizedBox(height: 32),

        // 同意条款复选框
        Row(
          children: [
            BlocSelector<SignHomeCubit, SignHomeState, bool>(
              selector: (state) => state.isAgreedToTerms,
              builder: (context, isAgreedToTerms) {
                return Checkbox(
                  value: isAgreedToTerms,
                  splashRadius: 0,
                  onChanged: (value) {
                    context.read<SignHomeCubit>().setIsAgreedToTerms(
                      isAgreed: value ?? false,
                    );
                  },
                  activeColor: Theme.of(context).primaryColor,
                );
              },
            ),
            Expanded(
              child: _buildAgreementText(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgreementText(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: l10n.readAndAgree),
          TextSpan(
            text: l10n.termsOfUse,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(l10n.userAgreementUrl),
          ),
          TextSpan(text: l10n.and),
          TextSpan(
            text: l10n.privacyPolicy,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(l10n.privacyAgreementUrl),
          ),
        ],
      ),
    );
  }
}
