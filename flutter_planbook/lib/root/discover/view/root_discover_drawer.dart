import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/discover/model/root_discover_tab.dart';
import 'package:flutter_planbook/root/task/view/root_drawer_list_tile.dart';
import 'package:flutter_planbook/root/task/view/root_user_header.dart';

class RootDiscoverDrawer extends StatelessWidget {
  const RootDiscoverDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      width: (MediaQuery.of(context).size.width * 0.85).clamp(280, 400),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
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
                for (final tab in RootDiscoverTab.values)
                  RootDrawerListTile(
                    icon: tab.icon,
                    iconBackgroundColor: tab.color,
                    title: tab.getName(context),
                    onPressed: () {
                      context.read<RootDiscoverBloc>().add(
                        RootDiscoverTabSelected(tab: tab),
                      );
                      Scaffold.of(context).closeDrawer();
                    },
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
