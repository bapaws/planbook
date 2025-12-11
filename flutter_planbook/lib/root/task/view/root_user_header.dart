import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

class RootUserHeader extends StatelessWidget {
  const RootUserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.router.push(const SettingsHomeRoute());
      },
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocSelector<AppBloc, AppState, UserEntity?>(
              selector: (state) => state.user,
              builder: (context, user) {
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final user = context.read<AppBloc>().state.user;
                        if (user == null) {
                          context.router.push(const SignHomeRoute());
                        } else {
                          context.router.push(const MineProfileRoute());
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.surfaceContainerHighest,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: user?.avatar == null
                            ? SvgPicture.asset(
                                'assets/images/logo.svg',
                                width: kMinInteractiveDimension,
                                height: kMinInteractiveDimension,
                              )
                            : AppNetworkImage(
                                url: user?.avatar,
                                bucket: ResBucket.userAvatars,
                                width: kMinInteractiveDimension,
                                height: kMinInteractiveDimension,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? context.l10n.notLoggedIn,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user != null)
                            Text(
                              context.l10n.joinedDaysAgo(user.joinDays),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      sizeStyle: CupertinoButtonSize.small,
                      child: const Icon(FontAwesomeIcons.gear),
                      onPressed: () {
                        context.router.push(const SettingsHomeRoute());
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
