import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
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

  bool _isTitleVisible = false;

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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    Text(activity.emoji, style: const TextStyle(fontSize: 72)),
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
                          data: '''
| 活动奖励 | 活动要求 |
|----------|--------|
| 月会员   | 五🌟好评   |
| 年会员   | 五🌟好评 + 4 篇笔记 |

*注意：由于兑换码限制，月会员和年会员活动，只能选择其中一种参与，不能同时参与。*

## 第❶步：App Store 评价

1. 点击「[**计划本**](https://apps.apple.com/app/id6737596725?action=write-review)」，打开 App Store。
2. 给「[**计划本**](https://apps.apple.com/app/id6737596725?action=write-review)」一个五🌟好评，也可以同时写下使用体验。

如果只参加月会员活动，请按照领取方式，将「**你的评分与评论**」页面的截图发送给「**计划本**」客服账户：[**Bapaws**](weixin://) 或 [**MC Studio**](xhsdiscover://user/6481492100000000120342c4)。
我们将在 24 小时内，发送会员兑换码。




## 第❷步：[小红书](xhsdiscover://post/) 发“截图或录屏”笔记

### *发布频率*

一天 1 篇，无需连续可以间隔。

### *笔记内容*
您可以发布各种关于「**计划本**」的笔记，包括但不限于以下的主题：

  + 使用心得
  + 喜欢或经常使用的功能
  + 一天的任务
  + 等等…

封面建议换换不同的，可用四象限或任务列表、任务周视图、任务月视图、笔记时间轴页、手账页等，利用期间摸索一下功能。

带上话题 **#计划本**

### *参考截图*
![screenshots](assets/images/screenshots.png)

### *⚠️注意：*
  - ❌**二次编辑笔记无效，因为无法确认笔记时间**
  - ❌禁止出现送会员、集赞、互踩、二维码、链接、容易平台限流。笔记需公开且保留1个月以上，否则收回会员。

''',
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
                          onTapLink: (text, href, title) {
                            if (href != null) {
                              launchUrl(Uri.parse(href));
                            }
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
                          if (text == 'Bapaws') {
                            await Clipboard.setData(ClipboardData(text: text));
                            await launchUrl(Uri.parse('weixin://'));
                          }
                          if (href != null) {
                            await launchUrl(Uri.parse(href));
                          }
                        },
                      ),
                    ],
                  ],
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
