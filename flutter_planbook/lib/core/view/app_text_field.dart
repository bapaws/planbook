import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.hintText,
    super.key,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.minLines,
    this.maxLines,
    this.textInputAction,
    this.maxLength,
  });

  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: textInputAction,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.outlineVariant,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
