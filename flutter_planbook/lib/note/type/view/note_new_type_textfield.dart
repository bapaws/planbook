import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/cubit/note_type_new_cubit.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:planbook_core/data/page_status.dart';

class NoteNewTypeTextfield extends StatefulWidget {
  const NoteNewTypeTextfield({
    super.key,
  });

  @override
  State<NoteNewTypeTextfield> createState() => _NoteNewTypeTextfieldState();
}

class _NoteNewTypeTextfieldState extends State<NoteNewTypeTextfield> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _initialFocusRequested = false;

  @override
  void initState() {
    super.initState();
    _controller.text = context.read<NoteTypeNewCubit>().state.content;
    if (context.read<NoteTypeNewCubit>().state.isReady) {
      _requestInitialFocus();
    }
  }

  void _requestInitialFocus() {
    if (_initialFocusRequested) return;
    _initialFocusRequested = true;
    // 等待本帧把输入框恢复为可编辑，再聚焦；后续编辑、保存或换日期不抢焦点。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<NoteTypeNewCubit>().state;
      if (!state.isReady || state.status == PageStatus.loading) {
        _initialFocusRequested = false;
        return;
      }
      if (ModalRoute.of(context)?.isCurrent == false) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<NoteTypeNewCubit, NoteTypeNewState>(
      listenWhen: (previous, current) => !previous.isReady && current.isReady,
      listener: (context, state) {
        _controller.text = state.content;
        _requestInitialFocus();
      },
      builder: (context, state) {
        final type = state.type;
        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: state.isReady && state.status != PageStatus.loading,
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
    );
  }
}
