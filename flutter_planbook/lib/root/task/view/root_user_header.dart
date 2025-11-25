import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_repository/planbook_repository.dart';

class RootUserHeader extends StatelessWidget {
  const RootUserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersRepository = context.read<UsersRepository>();
    final userProfile = usersRepository.userProfile;
    final user = usersRepository.user;
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(kMinInteractiveDimension),
                child: AppNetworkImage(
                  url: userProfile?.avatar,
                  bucket: ResBucket.userAvatars,
                  width: kMinInteractiveDimension,
                  height: kMinInteractiveDimension,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userProfile?.username ?? context.l10n.notLoggedIn),
                    if (user != null)
                      Text(context.l10n.joinedDaysAgo(user.joinDays)),
                  ],
                ),
              ),
              const CupertinoListTileChevron(),
            ],
          ),
        ),
      ),
    );
  }
}
