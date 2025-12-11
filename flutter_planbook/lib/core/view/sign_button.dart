import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum SignButtonStyle {
  normal,
  filled,
  outlined,
}

class SignButton extends StatelessWidget {
  const SignButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.style = SignButtonStyle.normal,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final SignButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = AnimatedSwitcher(
      duration: Durations.medium2,
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: style == SignButtonStyle.filled
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: style == SignButtonStyle.filled
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      onPressed: isLoading ? null : onPressed,
      minimumSize: const Size(double.infinity, kToolbarHeight),
      child: SizedBox(
        width: double.infinity,
        height: kToolbarHeight,
        child: switch (style) {
          SignButtonStyle.normal => _buildNormalButton(
            context,
            AnimatedSwitcher(
              duration: Durations.short4,
              child: child,
            ),
          ),
          SignButtonStyle.filled => _buildFilledButton(
            context,
            AnimatedSwitcher(duration: Durations.short4, child: child),
          ),
          SignButtonStyle.outlined => _buildOutlinedButton(
            context,
            AnimatedSwitcher(duration: Durations.short4, child: child),
          ),
        },
      ),
    );
  }

  Widget _buildNormalButton(BuildContext context, Widget child) {
    return child;
  }

  Widget _buildFilledButton(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _buildOutlinedButton(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: child,
    );
  }
}
