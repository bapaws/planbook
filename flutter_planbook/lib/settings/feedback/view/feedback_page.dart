import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:url_launcher/url_launcher_string.dart';

@RoutePage()
class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => const FeedbackPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(l10n.feedback),
        leading: const NavigationBarBackButton(),
      ),
      body: ListView(
        children: [
          SettingsRow(
            leading: const Icon(
              Icons.email,
              color: Colors.blue,
            ),
            title: Text(
              'Email',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            trailing: Row(
              children: [
                Text(
                  'dev@bapaws.com',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const CupertinoListTileChevron(),
              ],
            ),
            onPressed: () {},
          ),
          SettingsRow(
            leading: const Icon(
              Icons.wechat,
              color: Colors.green,
            ),
            title: Text(
              'WeChat',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            trailing: Row(
              children: [
                Text(
                  'MC Studio',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const CupertinoListTileChevron(),
              ],
            ),
            onPressed: () async {
              if (!kDebugMode && !await canLaunchUrlString('weixin://')) return;

              await Clipboard.setData(
                const ClipboardData(text: 'MC_AI_Studio'),
              );
              if (!context.mounted) return;

              await Fluttertoast.showToast(
                msg: context.l10n.weChatCopied,
                timeInSecForIosWeb: 2,
              );
            },
          ),
          FutureBuilder(
            future: canLaunchUrlString('weixin://'),
            builder: (context, snapshot) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/wx_qr.png',
                      width: 280,
                      // height: 280,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
          // SettingsRow(
          //   leading: const Icon(
          //     Icons.one_x_mobiledata,
          //     color: Colors.black,
          //   ),
          //   title: Text(
          //     'X',
          //     style: theme.textTheme.bodyLarge?.copyWith(
          //       color: theme.colorScheme.onSurface,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
