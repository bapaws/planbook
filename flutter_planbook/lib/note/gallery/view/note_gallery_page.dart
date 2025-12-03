import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/note/gallery/bloc/note_gallery_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:jiffy/jiffy.dart';

@RoutePage()
class NoteGalleryPage extends StatelessWidget {
  const NoteGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          NoteGalleryBloc(notesRepository: context.read())
            ..add(NoteGalleryRequested(date: Jiffy.now())),
      child: const _NoteGalleryPage(),
    );
  }
}

class _NoteGalleryPage extends StatelessWidget {
  const _NoteGalleryPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<NoteGalleryBloc, NoteGalleryState>(
      builder: (context, state) => state.noteImages.isEmpty
          ? const Center(child: Text('No images found'))
          : CustomScrollView(
              slivers: [
                for (final key in state.noteImages.keys) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      24,
                      16,
                      8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        key.toLocal().yMMMd,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 120,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                        ),
                    itemCount: state.noteImages[key]!.length,
                    itemBuilder: (context, index) => AppNetworkImage(
                      url: state.noteImages[key]![index].image,
                      width: 120,
                      height: 120,
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        16 +
                        kRootBottomBarHeight +
                        MediaQuery.of(context).padding.bottom,
                  ),
                ),
              ],
            ),
    );
  }
}
