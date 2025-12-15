import 'package:animate_do/animate_do.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide ColorScheme;
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_color_picker.dart';
import 'package:flutter_planbook/app/view/app_tag_icon.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_view.dart';
import 'package:flutter_planbook/tag/new/cubit/tag_new_cubit.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart' hide HexColorPlus;

@RoutePage()
class TagNewPage extends StatelessWidget {
  const TagNewPage({this.initialTag, super.key});
  final TagEntity? initialTag;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TagNewCubit(
            tagsRepository: context.read(),
            initialTag: initialTag,
          )..onRequested(),
        ),
        BlocProvider(
          create: (context) => TagListBloc(
            tagsRepository: context.read(),
            mode: TagListMode.singleSelect,
            notIncludeTagIds: initialTag != null ? {initialTag!.id} : const {},
          )..add(const TagListRequested()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TagNewCubit, TagNewState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == PageStatus.success) {
                context.router.maybePop();
              }
            },
          ),
          BlocListener<TagListBloc, TagListState>(
            listenWhen: (previous, current) =>
                previous.selectedTagIds != current.selectedTagIds,
            listener: (context, state) {
              final selectedTagId = state.selectedTagIds.firstOrNull;
              final selectedTag = state.tags.firstWhereOrNull(
                (tag) => tag.id == selectedTagId,
              );
              if (selectedTag != null) {
                context.read<TagNewCubit>().onParentTagChanged(
                  selectedTag,
                );
              }
            },
          ),
        ],
        child: const _TagNewPage(),
      ),
    );
  }
}

class _TagNewPage extends StatefulWidget {
  const _TagNewPage({super.key});

  @override
  State<_TagNewPage> createState() => _TagNewPageState();
}

class _TagNewPageState extends State<_TagNewPage> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<TagNewCubit>();
      final state = cubit.state;
      _nameController.text = state.initialTag?.name ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: AppPageScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBar(
              forceMaterialTransparency: true,
              title: const Text('New Tag'),
              leading: const NavigationBarBackButton(),
              actions: [
                CupertinoButton(
                  onPressed: () {
                    context.read<TagNewCubit>().onSave();
                  },
                  child: Text(context.l10n.save),
                ),
              ],
            ),
            BlocSelector<TagNewCubit, TagNewState, PageStatus>(
              selector: (state) => state.status,
              builder: (context, status) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    autofocus: true,
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    decoration: InputDecoration(
                      prefixIcon: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.square(
                          kMinInteractiveDimension,
                        ),
                        onPressed: () {
                          _showColorSchemePicker(context);
                        },
                        child: BlocBuilder<TagNewCubit, TagNewState>(
                          buildWhen: (previous, current) =>
                              previous.light != current.light ||
                              previous.dark != current.dark,
                          builder: (context, state) {
                            final brightness = Theme.of(context).brightness;
                            final colorScheme = brightness == Brightness.dark
                                ? state.dark
                                : state.light;
                            return AppTagIcon(
                              foregroundColor: colorScheme?.primary,
                              backgroundColor: colorScheme?.primaryContainer,
                            );
                          },
                        ),
                      ),
                      hintText: context.l10n.tagNameHint,
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            color: CupertinoColors.placeholderText,
                          ),
                      filled: true,
                      fillColor: CupertinoColors.systemGrey6,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onChanged: (value) {
                      context.read<TagNewCubit>().onNameChanged(value);
                    },
                    onSubmitted: (value) {
                      context.read<TagNewCubit>().onSave();
                    },
                  ).shakeX(animate: status == PageStatus.failure),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                context.l10n.parentTagHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CupertinoColors.tertiaryLabel,
                ),
              ),
            ),
            const Expanded(
              child: TagListView(),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorSchemePicker(BuildContext context) {
    final seedColor = context.read<TagNewCubit>().state.light?.argb;
    showColorSchemePicker(
      context,
      seedColor: seedColor != null ? Color(seedColor) : null,
      onColorSchemeChanged: (lightColorScheme, darkColorScheme) {
        context.read<TagNewCubit>().onColorSchemeChanged(
          ColorScheme.fromColorScheme(
            lightColorScheme,
          ),
          ColorScheme.fromColorScheme(
            darkColorScheme,
          ),
        );
      },
    );
  }
}
