import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/cubit/note_type_new_cubit.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:planbook_api/database/note_type.dart';

class NoteNewTypeTextfield extends StatefulWidget {
  const NoteNewTypeTextfield({
    super.key,
  });

  @override
  State<NoteNewTypeTextfield> createState() => _NoteNewTypeTextfieldState();
}

class _NoteNewTypeTextfieldState extends State<NoteNewTypeTextfield> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _controller.text = context.read<NoteTypeNewCubit>().state.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<NoteTypeNewCubit, NoteTypeNewState>(
      listenWhen: (previous, current) => previous.content != current.content,
      listener: (context, state) {
        _controller.text = state.content;
      },
      child: BlocSelector<NoteTypeNewCubit, NoteTypeNewState, NoteType>(
        selector: (state) => state.type,
        builder: (context, type) {
          return TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: type.isSummary
                  ? type.summaryType.getHintText(context.l10n)
                  : type.focusType.getHintText(context.l10n),
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outlineVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
            ),
            onChanged: context.read<NoteTypeNewCubit>().onContentChanged,
          );
        },
      ),
    );
  }
}
