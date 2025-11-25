import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_tag_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/new/cubit/note_new_cubit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart' hide Column;

class NoteNewView extends StatefulWidget {
  const NoteNewView({super.key});

  @override
  State<NoteNewView> createState() => _NoteNewViewState();
}

class _NoteNewViewState extends State<NoteNewView> {
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();

  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<NoteNewCubit>();
      final state = cubit.state;
      _titleController.text = state.title;
      _contentController.text = state.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final query = MediaQuery.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        BlocListener<NoteNewCubit, NoteNewState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == PageStatus.failure,
          listener: (context, state) {
            _titleFocusNode.requestFocus();
          },
          child: TextField(
            autofocus: true,
            controller: _titleController,
            focusNode: _titleFocusNode,
            minLines: 1,
            maxLines: 3,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: context.l10n.noteTitleHint,
              hintStyle: textTheme.titleLarge?.copyWith(
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
            ),
            onChanged: context.read<NoteNewCubit>().onTitleChanged,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _contentController,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            minLines: 3,
            maxLines: 20,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: context.l10n.noteContentHint,
              hintStyle: textTheme.bodyLarge?.copyWith(
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
            ),
            onChanged: context.read<NoteNewCubit>().onContentChanged,
          ),
        ),
        BlocSelector<NoteNewCubit, NoteNewState, List<String>>(
          selector: (state) => state.images,
          builder: (context, images) {
            if (images.isEmpty) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: 80 + 12,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imagePath = images[index];
                  final isLocalFile =
                      !imagePath.startsWith('http://') &&
                      !imagePath.startsWith('https://');
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: isLocalFile
                              ? Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: imagePath,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CupertinoActivityIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            context.read<NoteNewCubit>().removeImage(
                              index,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
        BlocSelector<NoteNewCubit, NoteNewState, List<TagEntity>>(
          selector: (state) => state.tags,
          builder: (context, tags) {
            return AnimatedSwitcher(
              duration: Durations.medium1,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: tags.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 26 + 12,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 4),
                        itemCount: tags.length,
                        itemBuilder: (context, index) {
                          return AppTagView(
                            tag: tags[index],
                            onTap: () {
                              context.read<NoteNewCubit>().removeTag(index);
                            },
                          );
                        },
                      ),
                    ),
            );
          },
        ),
        BlocSelector<NoteNewCubit, NoteNewState, Task?>(
          selector: (state) => state.task,
          builder: (context, task) {
            return AnimatedSwitcher(
              duration: Durations.medium1,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              ),
              child: task == null
                  ? const SizedBox.shrink()
                  : CupertinoButton(
                      minimumSize: const Size.square(26),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      onPressed: () {
                        context.read<NoteNewCubit>().removeTask();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.primaryContainer,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.paperclip,
                              color: colorScheme.onSurface,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.title,
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          },
        ),
        Row(
          children: [
            CupertinoButton(
              padding: const EdgeInsets.all(16),
              onPressed: () async {
                final picker = ImagePicker();
                final files = await picker.pickMultiImage(limit: 9);
                if (!context.mounted) return;

                final paths = files.map((file) => file.path).toList();
                context.read<NoteNewCubit>().addImages(paths);
              },
              child: Icon(
                FontAwesomeIcons.solidImage,
                color: colorScheme.onSurface,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size.square(kMinInteractiveDimension),
              onPressed: () async {
                final picker = ImagePicker();
                final file = await picker.pickImage(
                  source: ImageSource.camera,
                );

                if (!context.mounted || file == null) return;
                context.read<NoteNewCubit>().addImages([file.path]);
              },
              child: Icon(
                FontAwesomeIcons.solidCamera,
                color: colorScheme.onSurface,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size.square(kMinInteractiveDimension),
              onPressed: () {
                final tags = context.read<NoteNewCubit>().state.tags;
                context.router.push(
                  TagPickerRoute(
                    selectedTags: tags,
                    onSelected: (selectedTags) {
                      context.read<NoteNewCubit>().onTagsChanged(selectedTags);
                    },
                  ),
                );
              },
              child: Icon(
                FontAwesomeIcons.tags,
                color: colorScheme.onSurface,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size.square(kMinInteractiveDimension),
              onPressed: () async {
                final result = await context.router.push<TaskEntity>(
                  const TaskPickerRoute(),
                );
                if (result != null && context.mounted) {
                  context.read<NoteNewCubit>().onTaskSelected(
                    result,
                  );
                }
              },
              child: Icon(
                FontAwesomeIcons.paperclip,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            CupertinoButton(
              padding: const EdgeInsets.all(16),
              onPressed: () {
                context.read<NoteNewCubit>().onSave();
              },
              child: Icon(
                FontAwesomeIcons.solidPaperPlane,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: query.padding.bottom + query.viewInsets.bottom),
      ],
    );
  }
}
