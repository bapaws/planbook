import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/email/mailto_with_app_info.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class AppActivityPage extends StatefulWidget {
  const AppActivityPage({
    required this.activity,
    super.key,
  });

  final ActivityMessageEntity activity;

  @override
  State<AppActivityPage> createState() => _AppActivityPageState();
}

class _AppActivityPageState extends State<AppActivityPage> {
  ActivityMessageEntity get activity => widget.activity;

  final ScrollController _scrollController = ScrollController();
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _isTitleVisible = false;

  Future<void> _openMarkdownLink(String? text, String? href) async {
    if (href == null) return;
    if (href.startsWith('weixin://')) {
      final code = href.split('://').last;
      await Clipboard.setData(ClipboardData(text: code));
      await launchUrl(Uri.parse('weixin://'));
      return;
    }

    final uri = Uri.tryParse(href);
    if (uri == null) return;

    if (uri.scheme == 'mailto') {
      final mailtoUri = await mailtoWithAppInfo(uri);
      if (!mounted) return;
      await launchUrl(mailtoUri);
      return;
    }

    if (!mounted) return;
    await launchUrl(uri);
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final isTitleVisible = _scrollController.position.pixels > 100;
      if (isTitleVisible != _isTitleVisible) {
        setState(() {
          _isTitleVisible = isTitleVisible;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: _isTitleVisible ? Text(activity.emoji + activity.title) : null,
        leading: const NavigationBarBackButton(),
        centerTitle: false,
        actions: [
          Builder(
            builder: (context) {
              return CupertinoButton(
                child: const Icon(CupertinoIcons.share),
                onPressed: () async {
                  final image = await _screenshotController.capture();
                  if (image == null || !context.mounted) return;

                  // ImageGallerySaver.saveImage(image);

                  final box = context.findRenderObject() as RenderBox?;
                  await SharePlus.instance.share(
                    ShareParams(
                      title: activity.title,
                      files: [XFile.fromData(image, mimeType: 'image/png')],
                      sharePositionOrigin:
                          box!.localToGlobal(Offset.zero) & box.size,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                child: Screenshot(
                  controller: _screenshotController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        Text(
                          activity.emoji,
                          style: const TextStyle(fontSize: 72),
                        ),
                        Text(
                          activity.title,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (activity.content != null)
                          SizedBox(
                            width: double.infinity,
                            child: Markdown(
                              data: activity.content!,
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              styleSheet: MarkdownStyleSheet(
                                h1: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                h1Padding: const EdgeInsets.only(top: 48),
                                h2: textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                h2Padding: const EdgeInsets.only(top: 32),
                                h3: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                h3Padding: const EdgeInsets.only(top: 16),
                              ),
                              imageBuilder: (uri, title, alt) {
                                final uriString = uri.toString();
                                if (uriString.startsWith('assets/')) {
                                  return Image.asset(
                                    uriString,
                                    fit: BoxFit.contain,
                                  );
                                }
                                return Image.network(
                                  uriString,
                                  fit: BoxFit.contain,
                                );
                              },
                              onTapLink: (text, href, title) async {
                                await _openMarkdownLink(text, href);
                              },
                            ),
                          ),
                        if (activity.illustration != null)
                          SvgPicture.asset(
                            'assets/images/${activity.illustration!}',
                            width: MediaQuery.of(context).size.width,
                            fit: BoxFit.cover,
                          ),
                        if (activity.receiveWay != null) ...[
                          Divider(
                            color: colorScheme.surfaceContainerHighest,
                            height: kMinInteractiveDimension,
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            // onPressed: () {
                            //   setState(() {
                            //     _isReceiveWayVisible = !_isReceiveWayVisible;
                            //   });
                            // },
                            onPressed: null,
                            child: Text(
                              context.l10n.receiveWay,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ),
                          Markdown(
                            data: activity.receiveWay!,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            styleSheet: MarkdownStyleSheet(
                              h1: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              h1Padding: const EdgeInsets.only(top: 32),
                              h2: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              h2Padding: const EdgeInsets.only(top: 24),
                              h3: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              h3Padding: const EdgeInsets.only(top: 12),
                              p: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            onTapLink: (text, href, title) async {
                              await _openMarkdownLink(text, href);
                            },
                            sizedImageBuilder: (config) {
                              final uriString = config.uri.toString();
                              if (uriString.startsWith('assets/')) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    uriString,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              }
                              return Image.network(
                                uriString,
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: CupertinoButton.tinted(
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () {
                        context.read<AppActivityBloc>().add(
                          AppActivityNotShowAgain(
                            message: activity,
                          ),
                        );

                        context.router.maybePop();
                      },
                      child: Text(
                        context.l10n.notShowAgain,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton.filled(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () async {
                        if (activity.openURL == null) return;
                        await launchUrl(Uri.parse(activity.openURL!));
                        if (context.mounted) {
                          context.read<AppActivityBloc>().add(
                            AppActivityNotShowAgain(
                              message: activity,
                            ),
                          );
                        }
                      },
                      child: Text(activity.openTitle ?? context.l10n.done),
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
