import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_tag_icon.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/tag/detail/bloc/tag_detail_bloc.dart';
import 'package:flutter_planbook/tag/detail/view/tag_detail_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/tag_entity.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:pull_down_button/pull_down_button.dart';

@RoutePage()
class TagDetailPage extends StatelessWidget {
  const TagDetailPage({
    required this.tag,
    super.key,
  });

  final TagEntity tag;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TagDetailBloc(
        notesRepository: context.read(),
        tagsRepository: context.read(),
        tag: tag,
      )..add(const TagDetailRequested()),
      child: BlocListener<TagDetailBloc, TagDetailState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == PageStatus.loading) {
            EasyLoading.show(maskType: EasyLoadingMaskType.clear);
          } else if (EasyLoading.isShow) {
            EasyLoading.dismiss();
          }
          if (state.status == PageStatus.dispose) {
            context.router.maybePop();
          }
        },
        child: const _TagDetailPage(),
      ),
    );
  }
}

class _TagDetailPage extends StatelessWidget {
  const _TagDetailPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          leading: const NavigationBarBackButton(),
          titleSpacing: 0,
          title: BlocSelector<TagDetailBloc, TagDetailState, TagEntity>(
            selector: (state) => state.tag,
            builder: (context, tag) {
              final tagColorScheme = theme.brightness == Brightness.dark
                  ? tag.dark
                  : tag.light;
              return Row(
                children: [
                  AppTagIcon.fromTagEntity(tag, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      tag.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            tagColorScheme?.onSurface ?? colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            PullDownButton(
              itemBuilder: (context) {
                final theme = Theme.of(context);
                return [
                  PullDownMenuItem(
                    icon: FontAwesomeIcons.penToSquare.data,
                    iconColor: theme.colorScheme.primary,
                    title: context.l10n.edit,
                    onTap: () {
                      final tag = context.read<TagDetailBloc>().state.tag;
                      context.router.push(TagNewRoute(initialTag: tag));
                    },
                  ),
                  const PullDownMenuDivider.large(),
                  PullDownMenuItem(
                    icon: FontAwesomeIcons.trash.data,
                    title: context.l10n.delete,
                    isDestructive: true,
                    onTap: () => _showDeleteConfirmation(context),
                  ),
                ];
              },
              buttonBuilder: (context, showMenu) => CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(kMinInteractiveDimension),
                onPressed: showMenu,
                child: const FaIcon(FontAwesomeIcons.ellipsis),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: theme.textTheme.labelLarge,
              tabs: [
                Tab(text: l10n.searchTasks),
                Tab(text: l10n.searchNotes),
              ],
            ),
          ),
        ),
        body: const TagDetailView(),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final bloc = context.read<TagDetailBloc>();
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.deleteTag),
        content: Text(context.l10n.deleteTagContent),
        actions: [
          CupertinoDialogAction(
            child: Text(context.l10n.cancel),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(const TagDetailDeleted());
            },
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
}
