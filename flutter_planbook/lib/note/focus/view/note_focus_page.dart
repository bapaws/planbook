import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/focus/cubit/note_focus_cubit.dart';
import 'package:flutter_planbook/note/focus/model/note_type_x.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class NoteFocusPage extends StatelessWidget {
  const NoteFocusPage({
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
      create: (context) => NoteFocusCubit(
        notesRepository: context.read(),
        initialNote: initialNote,
        type: type,
        focusAt: focusAt,
        l10n: l10n,
      ),
      child: BlocListener<NoteFocusCubit, NoteFocusState>(
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
        child: const _NoteFocusPage(),
      ),
    );
  }
}

class _NoteFocusPage extends StatelessWidget {
  const _NoteFocusPage();

  @override
  Widget build(BuildContext context) {
    final type = context.read<NoteFocusCubit>().type;
    final theme = Theme.of(context);
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.vertical,
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        controller: PrimaryScrollController.of(context),
        child: Column(
          children: [
            AppBar(
              leading: const NavigationBarCloseButton(),
              title: Text(type.getTitle(context.l10n)),
            ),
            TextFormField(
              autofocus: true,
              maxLines: 6,
              initialValue: context.read<NoteFocusCubit>().state.content,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: type.getHintText(context.l10n),
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outlineVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
              ),
              onChanged: context.read<NoteFocusCubit>().onContentChanged,
            ),
            Row(
              children: [
                const Spacer(),
                CupertinoButton(
                  onPressed: context.read<NoteFocusCubit>().onSave,
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
