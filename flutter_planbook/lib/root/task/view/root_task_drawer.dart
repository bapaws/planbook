import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/task_list_mode_x.dart';
import 'package:flutter_planbook/root/task/view/root_drawer_list_tile.dart';
import 'package:flutter_planbook/root/task/view/root_user_header.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:pull_down_button/pull_down_button.dart';

class RootTaskDrawer extends StatelessWidget {
  const RootTaskDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      width: (MediaQuery.of(context).size.width * 0.85).clamp(280, 400),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const RootUserHeader(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 16,
                  ),
                ),
                for (final mode in [
                  TaskListMode.inbox,
                  TaskListMode.today,
                  TaskListMode.overdue,
                ])
                  BlocSelector<RootTaskBloc, RootTaskState, int>(
                    selector: (state) => state.taskCounts[mode] ?? 0,
                    builder: (context, count) {
                      return RootDrawerListTile(
                        icon: mode.icon,
                        iconBackgroundColor: mode.color,
                        title: mode.getName(context),
                        count: count,
                        onPressed: () {
                          context.read<RootTaskBloc>().add(
                            RootTaskTabSelected(tab: mode),
                          );

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
                                context.router.push(TagNewRoute());
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
}
