import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_core/planbook_core.dart';

Future<bool?> showColorPicker(
  BuildContext context, {
  required ValueChanged<Color> onColorChanged,
  Color? color,
}) async {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            AppBar(
              forceMaterialTransparency: true,
              title: Text(context.l10n.selectColor),
              leading: const NavigationBarBackButton(),
              actions: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(context.l10n.save),
                ),
              ],
            ),
            ColorPicker(
              // Use the dialogPickerColor as start and active color.
              color: color ?? Colors.red,
              // Update the dialogPickerColor using the callback.
              onColorChanged: onColorChanged,
              borderRadius: 20,
              spacing: 6,
              runSpacing: 6,
              wheelDiameter: 200,
              columnSpacing: 32,
              toolbarSpacing: 12,
              wheelSquarePadding: 4,
              // subheading: Text(
              //   'Select color shade',
              //   style: Theme.of(context).textTheme.titleSmall,
              // ),
              // wheelSubheading: Text(
              //   'Selected color and its shades',
              //   style: Theme.of(context).textTheme.titleSmall,
              // ),
              // showMaterialName: true,
              // showColorName: true,
              // showColorCode: true,
              copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                editFieldCopyButton: false,
                editUsesParsedPaste: false,
              ),
              enableTooltips: false,
              materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
                ColorPickerType.wheel: true,
              },
              // customColorSwatchesAndNames: colorsNameMap,
            ),
          ],
        ),
      );
    },
  );
}

typedef ColorSchemeChanged =
    void Function(
      ColorScheme light,
      ColorScheme dark,
    );

Future<bool?> showColorSchemePicker(
  BuildContext context, {
  required ColorSchemeChanged onColorSchemeChanged,
  Color? seedColor,
}) async {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return Container(
        constraints: const BoxConstraints(
          maxHeight: 360,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: AppPageScaffold(
          child: ColorSchemePicker(
            seedColor: seedColor ?? Colors.red,
            onColorSchemeChanged: onColorSchemeChanged,
          ),
        ),
      );
    },
  );
}

class ColorSchemePicker extends StatefulWidget {
  const ColorSchemePicker({
    required this.onColorSchemeChanged,
    this.seedColor = Colors.red,
    super.key,
  });

  final Color seedColor;
  final ColorSchemeChanged onColorSchemeChanged;

  @override
  State<ColorSchemePicker> createState() => _ColorSchemePickerState();
}

class _ColorSchemePickerState extends State<ColorSchemePicker> {
  late ColorScheme _lightColorScheme;
  late ColorScheme _darkColorScheme;

  int _redValue = 0;
  int _greenValue = 0;
  int _blueValue = 0;

  Color get seedColor => Color.fromARGB(
    255,
    _redValue,
    _greenValue,
    _blueValue,
  );

  void _updateValues({
    int? redValue,
    int? greenValue,
    int? blueValue,
  }) {
    setState(() {
      _redValue = redValue ?? _redValue;
      _greenValue = greenValue ?? _greenValue;
      _blueValue = blueValue ?? _blueValue;

      final seedColor = Color.fromARGB(
        255,
        _redValue,
        _greenValue,
        _blueValue,
      );
      _lightColorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
      );
      _darkColorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      );
    });

    widget.onColorSchemeChanged(_lightColorScheme, _darkColorScheme);
  }

  @override
  void initState() {
    super.initState();

    _redValue = (widget.seedColor.r * 255).round();
    _greenValue = (widget.seedColor.g * 255).round();
    _blueValue = (widget.seedColor.b * 255).round();

    _lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
    );
    _darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.brightness == Brightness.dark
        ? _darkColorScheme
        : _lightColorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text(
                  'Seed Color',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  seedColor.toHex().toUpperCase(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: seedColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              spacing: 4,
              children: [
                Text(
                  'Shades',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                for (final color in [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest,
                ]) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.surfaceContainerHighest,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('R'),
              Expanded(
                child: Slider(
                  value: _redValue / 255,
                  activeColor: const Color.fromARGB(255, 255, 0, 0),
                  onChanged: (value) {
                    _updateValues(redValue: (value * 255).round());
                  },
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$_redValue',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('G'),
              Expanded(
                child: Slider(
                  value: _greenValue / 255,
                  activeColor: const Color.fromARGB(255, 0, 255, 0),
                  onChanged: (value) {
                    _updateValues(greenValue: (value * 255).round());
                  },
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$_greenValue',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('B'),
              Expanded(
                child: Slider(
                  value: _blueValue / 255,
                  activeColor: const Color.fromARGB(255, 0, 0, 255),
                  onChanged: (value) {
                    _updateValues(blueValue: (value * 255).round());
                  },
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$_blueValue',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
