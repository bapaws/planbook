import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/note/bloc/root_note_bloc.dart';
import 'package:flutter_planbook/root/task/view/root_drawer_list_tile.dart';
import 'package:flutter_planbook/root/task/view/root_user_header.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pull_down_button/pull_down_button.dart';

class RootNoteDrawer extends StatelessWidget {
  const RootNoteDrawer({super.key});

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
                RootDrawerListTile(
                  icon: FontAwesomeIcons.timeline,
                  iconBackgroundColor: Colors.orange,
                  title: context.l10n.timeline,
                  onPressed: () {
                    context.read<RootNoteBloc>().add(
                      const RootNoteTabSelected(tab: RootNoteTab.timeline),
                    );
                    Scaffold.of(context).closeDrawer();
                  },
                ),
                RootDrawerListTile(
                  icon: FontAwesomeIcons.filePen,
                  iconBackgroundColor: Colors.blue,
                  title: context.l10n.note,
                  onPressed: () {
                    context.read<RootNoteBloc>().add(
                      const RootNoteTabSelected(tab: RootNoteTab.written),
                    );
                    Scaffold.of(context).closeDrawer();
                  },
                ),
                RootDrawerListTile(
                  icon: FontAwesomeIcons.listCheck,
                  iconBackgroundColor: Colors.brown,
                  title: context.l10n.task,
                  onPressed: () {
                    context.read<RootNoteBloc>().add(
                      const RootNoteTabSelected(tab: RootNoteTab.task),
                    );
                    Scaffold.of(context).closeDrawer();
                  },
                ),
                RootDrawerListTile(
                  icon: FontAwesomeIcons.image,
                  iconBackgroundColor: Colors.green,
                  title: context.l10n.gallery,
                  onPressed: () {
                    context.read<RootNoteBloc>().add(
                      const RootNoteTabSelected(tab: RootNoteTab.gallery),
                    );
                    Scaffold.of(context).closeDrawer();
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
                          context.read<RootNoteBloc>().add(
                            RootNoteTagSelected(tag: tag),
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

  Future<void> _onAddTagTapped(BuildContext context) async {
    if (await context.read<AppPurchasesBloc>().isTagLimitReached() &&
        context.mounted) {
      await context.router.push(const AppPurchasesRoute());
      return;
    }
    await context.router.push(TagNewRoute());
  }
}
