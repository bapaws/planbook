import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/activity/view/app_activity_item_view.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/root/task/view/root_drawer_list_tile.dart';
import 'package:flutter_planbook/root/task/view/root_user_header.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pull_down_button/pull_down_button.dart';

class RootTaskDrawer extends StatelessWidget {
  const RootTaskDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      width: (MediaQuery.of(context).size.width * 0.85).clamp(280, 400),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          const RootUserHeader(),
          BlocBuilder<AppActivityBloc, AppActivityState>(
            builder: (context, state) {
              return state.activities.isNotEmpty
                  ? AppActivityItemView(activity: state.activities[0])
                  : const SizedBox.shrink();
            },
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 16,
                  ),
                ),
                for (final tab in [
                  RootTaskTab.inbox,
                  RootTaskTab.overdue,
                  RootTaskTab.day,
                  RootTaskTab.week,
                  RootTaskTab.month,
                ])
                  BlocSelector<RootTaskBloc, RootTaskState, int?>(
                    selector: (state) => state.taskCounts[tab.mode],
                    builder: (context, count) {
                      return RootDrawerListTile(
                        icon: tab.icon,
                        iconBackgroundColor: tab.color,
                        title: tab.getName(context),
                        count: count,
                        isSelected: context.tabsRouter.activeIndex == tab.index,
                        onPressed: () {
                          context.tabsRouter.setActiveIndex(tab.index);

                          Scaffold.of(context).closeDrawer();
                        },
                      );
                    },
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          context.l10n.tag,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const Spacer(),
                        PullDownButton(
                          itemBuilder: (context) => [
                            PullDownMenuItem(
                              icon: FontAwesomeIcons.plus,
                              title: context.l10n.addTag,
                              onTap: () {
                                _onAddTagTapped(context);
                              },
                            ),
                          ],
                          buttonBuilder: (context, showMenu) => CupertinoButton(
                            padding: EdgeInsets.zero,
                            sizeStyle: CupertinoButtonSize.small,
                            onPressed: showMenu,
                            child: const Icon(FontAwesomeIcons.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                BlocBuilder<RootHomeBloc, RootHomeState>(
                  buildWhen: (previous, current) =>
                      previous.tags != current.tags,
                  builder: (context, state) => SliverList.builder(
                    itemCount: state.tags.length,
                    itemBuilder: (context, index) {
                      final tag = state.tags[index];
                      return TagListTile(
                        tag: tag,
                        onSelected: () {
                          context.read<RootTaskBloc>().add(
                            RootTaskTagSelected(tag: tag),
                          );
                          // context.tabsRouter.setActiveIndex(
                          //   RootTaskTab.tag.index,
                          // );
                          Scaffold.of(context).closeDrawer();
                        },
                        onDeleted: () {
                          context.read<RootHomeBloc>().add(
                            RootHomeTagDeleted(tagId: tag.id),
                          );
                          Scaffold.of(context).closeDrawer();
                        },
                        onEdited: () {
                          context.router.push(TagNewRoute(initialTag: tag));
                          Scaffold.of(context).closeDrawer();
                        },
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        16 +
                        MediaQuery.of(context).padding.bottom +
                        kToolbarHeight,
                  ),
                ),
              ],
            ),
          ),
        ],
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
