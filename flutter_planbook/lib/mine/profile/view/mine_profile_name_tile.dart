import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/view/app_tile.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

class MineProfileNameTile extends StatefulWidget {
  const MineProfileNameTile({
    required this.name,
    required this.onChanged,
    super.key,
  });

  final String name;
  final ValueChanged<String> onChanged;

  @override
  State<MineProfileNameTile> createState() => _MineProfileNameTileState();
}

class _MineProfileNameTileState extends State<MineProfileNameTile> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _controller.text = widget.name;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppTile.text(
      title: context.l10n.nickname,
      onPressed: () {
        _focusNode.requestFocus();
        // 将光标定位到文本的最后
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      },
      trailing: Expanded(
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onSubmitted: (value) {
            widget.onChanged(value);
          },
        ),
      ),
    );
  }
}
