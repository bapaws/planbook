import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/cubit/note_type_new_cubit.dart';
import 'package:flutter_planbook/note/type/view/note_new_type_textfield.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class NoteNewTypePage extends StatelessWidget {
  const NoteNewTypePage({
    required this.type,
    required this.focusAt,
    this.initialNote,
    super.key,
  });

  final Note? initialNote;
  final NoteType type;
  final Jiffy focusAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) => NoteTypeNewCubit(
        notesRepository: context.read(),
        type: type,
        focusAt: focusAt,
        initialNote: initialNote,
        l10n: l10n,
      ),
      child: BlocListener<NoteTypeNewCubit, NoteTypeNewState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == PageStatus.loading) {
            EasyLoading.show(maskType: EasyLoadingMaskType.clear);
          } else if (EasyLoading.isShow) {
            EasyLoading.dismiss();
          }
          if (state.status == PageStatus.success) {
            context.router.maybePop();
          }
        },
        child: DefaultTabController(
          length: 2,
          initialIndex: type.isSummary ? 1 : 0,
          child: const _NoteNewTypePage(),
        ),
      ),
    );
  }
}

class _NoteNewTypePage extends StatelessWidget {
  const _NoteNewTypePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        controller: PrimaryScrollController.of(context),
        child: Column(
          children: [
            AppBar(
              leading: const NavigationBarCloseButton(),
              title: BlocSelector<NoteTypeNewCubit, NoteTypeNewState, String>(
                selector: (state) => state.getTitle(context.l10n),
                builder: (context, title) {
                  return Text(
                    title,
                    style: theme.appBarTheme.titleTextStyle?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
            const NoteNewTypeTextfield(),
            Row(
              children: [
                const Spacer(),
                CupertinoButton(
                  onPressed: () {
                    context.read<NoteTypeNewCubit>().onSave();
                  },
                  child: const Icon(FontAwesomeIcons.solidPaperPlane),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
