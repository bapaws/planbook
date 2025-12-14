import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/note/new/cubit/note_new_cubit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planbook_api/entity/task_entity.dart';

class NoteNewBottomBar extends StatelessWidget {
  const NoteNewBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CupertinoButton(
          padding: const EdgeInsets.all(16),
          onPressed: () async {
            if (!context.read<AppPurchasesBloc>().isPremium) {
              await context.router.push(const AppPurchasesRoute());
              return;
            }

            final picker = ImagePicker();
            final files = await picker.pickMultiImage(limit: 9);
            if (!context.mounted) return;

            final paths = files.map((file) => file.path).toList();
            await context.read<NoteNewCubit>().addImages(paths);
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
            if (!context.read<AppPurchasesBloc>().isPremium) {
              await context.router.push(const AppPurchasesRoute());
              return;
            }

            final picker = ImagePicker();
            final file = await picker.pickImage(
              source: ImageSource.camera,
            );

            if (!context.mounted || file == null) return;
            await context.read<NoteNewCubit>().addImages([file.path]);
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
          minimumSize: const Size.square(kMinInteractiveDimension),
          onPressed: () {
            context.read<NoteNewCubit>().onSave();
          },
          child: Icon(
            FontAwesomeIcons.solidPaperPlane,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
