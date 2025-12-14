import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TagNewButton extends StatelessWidget {
  const TagNewButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: kMinInteractiveDimension * 2,
      width: 180,
      child: Center(
        child: CupertinoButton.tinted(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: const Size.square(kMinInteractiveDimension),
          sizeStyle: CupertinoButtonSize.medium,
          borderRadius: BorderRadius.circular(100),
          onPressed: () {
            _onAddTagTapped(context);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.plus,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.addTag,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAddTagTapped(BuildContext context) async {
    if (await context.read<AppPurchasesBloc>().isTagLimitReached() &&
        context.mounted) {
      await context.router.push(const AppPurchasesRoute());
      return;
    }
    await context.router.push(TagNewRoute());
  }
}
