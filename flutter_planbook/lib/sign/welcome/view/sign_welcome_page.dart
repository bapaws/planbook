import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/core/view/sign_button.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/sign/home/cubit/sign_home_cubit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  Future<bool> _isAgreedToTerms(BuildContext context) async {
    final isAgreedToTerms = context.read<SignHomeCubit>().state.isAgreedToTerms;
    if (isAgreedToTerms) {
      return true;
    } else {
      final isAgreed = await _showAgreementDialog(context);
      return isAgreed ?? false;
    }
  }

  Future<void> _handleSignInWithCode(BuildContext context) async {
    final isAgreedToTerms = await _isAgreedToTerms(context);
    if (isAgreedToTerms && context.mounted) {
      context.read<SignHomeCubit>().signInWithCode();
    }
  }

  Future<void> _handleSignInWithPhone(BuildContext context) async {
    final isAgreedToTerms = await _isAgreedToTerms(context);
    if (isAgreedToTerms && context.mounted) {
      context.read<SignHomeCubit>().signInWithPhone();
    }
  }

  Future<void> _handleSignInWithEmail(BuildContext context) async {
    final isAgreedToTerms = await _isAgreedToTerms(context);
    if (isAgreedToTerms && context.mounted) {
      context.read<SignHomeCubit>().signInWithEmail();
    }
  }

  Future<void> _handleSignInWithPassword(BuildContext context) async {
    final isAgreedToTerms = await _isAgreedToTerms(context);
    if (isAgreedToTerms && context.mounted) {
      context.read<SignHomeCubit>().signInWithPassword();
    }
  }

  Future<void> _handleSignInWithApple(BuildContext context) async {
    final isAgreedToTerms = await _isAgreedToTerms(context);
    if (isAgreedToTerms && context.mounted) {
      context.read<SignHomeCubit>().signInWithApple();
    }
  }

  Future<void> _handleSignInWithGoogle(BuildContext context) async {
    final isAgreedToTerms = await _isAgreedToTerms(context);
    if (isAgreedToTerms && context.mounted) {
      context.read<SignHomeCubit>().signInWithGoogle();
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
    final locale = Localizations.localeOf(context);
    final isChineseLocale = locale.languageCode == 'zh';

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

        // 主登录按钮：中文环境用手机，其他用邮箱
        SignButton(
          text: l10n.useCodeLogin,
          style: SignButtonStyle.filled,
          onPressed: () {
            if (isChineseLocale) {
              _handleSignInWithCode(context);
            } else {
              _handleSignInWithEmail(context);
            }
          },
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            if (Platform.isIOS)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  width: kMinInteractiveDimension,
                  height: kMinInteractiveDimension,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      kMinInteractiveDimension,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  child: Icon(
                    FontAwesomeIcons.apple,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () => _handleSignInWithApple(context),
              ),
            if (isChineseLocale)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  width: kMinInteractiveDimension,
                  height: kMinInteractiveDimension,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      kMinInteractiveDimension,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  child: Icon(
                    FontAwesomeIcons.phone,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () => _handleSignInWithPhone(context),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                width: kMinInteractiveDimension,
                height: kMinInteractiveDimension,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kMinInteractiveDimension),
                  border: Border.all(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Icon(
                  FontAwesomeIcons.envelope,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onPressed: () => _handleSignInWithEmail(context),
            ),
            // CupertinoButton(
            //   padding: EdgeInsets.zero,
            //   child: Container(
            //     width: kMinInteractiveDimension,
            //     height: kMinInteractiveDimension,
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(kMinInteractiveDimension),
            //       border: Border.all(
            //         color: theme.colorScheme.surfaceContainerHighest,
            //       ),
            //     ),
            //     child: Icon(
            //       FontAwesomeIcons.google,
            //       color: theme.colorScheme.onSurface,
            //     ),
            //   ),
            //   onPressed: () => _handleSignInWithGoogle(context),
            // ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                width: kMinInteractiveDimension,
                height: kMinInteractiveDimension,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kMinInteractiveDimension),
                  border: Border.all(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Icon(
                  FontAwesomeIcons.key,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onPressed: () => _handleSignInWithPassword(context),
            ),
          ],
        ),

        const SizedBox(height: 24),
        // 密码登录按钮
        // SignButton(
        //   text: l10n.usePasswordLogin,
        //   onPressed: () => _handleSignInWithPassword(context),
        //   style: SignButtonStyle.outlined,
        // ),

        // const SizedBox(height: 16),
        // // 验证码登录按钮
        // SignButton(
        //   text: l10n.usePhoneLogin,
        //   style: SignButtonStyle.filled,
        //   onPressed: () => _handleSignInWithApple(context),
        // ),

        // const SizedBox(height: 16),

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
                  activeColor: theme.colorScheme.primary,
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
