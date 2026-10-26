import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/view/app_color_picker.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/discover/diary/bloc/diary_notebook_bloc.dart';
import 'package:flutter_planbook/discover/diary/model/diary_notebook_look.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:paper_notebook/paper_notebook.dart';
import 'package:pull_down_button/pull_down_button.dart';

/// 当年日记本外观。版式、底图、颜色、纹理、纸张和 Jotbook 的笔记本设置相同。
@RoutePage()
class DiaryNotebookSettingsPage extends StatefulWidget {
  const DiaryNotebookSettingsPage({required this.year, super.key});

  final int year;

  @override
  State<DiaryNotebookSettingsPage> createState() =>
      _DiaryNotebookSettingsPageState();
}

class _DiaryNotebookSettingsPageState extends State<DiaryNotebookSettingsPage> {
  final _colorByTemplate = <PaperNotebookCoverTemplate, Color>{};
  List<PaperNotebookCoverSpec> _covers = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadCovers());
  }

  Future<void> _loadCovers() async {
    final covers = await PaperNotebookCoverCatalog.load();
    if (!mounted) return;
    setState(() => _covers = covers);
  }

  DiaryNotebookLook _look(DiaryNotebookState state) =>
      state.lookFor(widget.year);

  Color _colorFor(DiaryNotebookLook look, PaperNotebookCoverTemplate template) {
    return _colorByTemplate[template] ??
        (template == look.template ? look.color : template.defaultColor);
  }

  void _onChange(DiaryNotebookLook Function(DiaryNotebookLook current) update) {
    final bloc = context.read<DiaryNotebookBloc>();
    final current = _look(bloc.state);
    final next = update(current);
    if (next == current) return;
    _colorByTemplate[current.template] = current.color;
    _colorByTemplate[next.template] = next.color;
    bloc.add(DiaryNotebookSaved(year: widget.year, look: next));
  }

  Future<void> _pickCustomColor(DiaryNotebookLook look) async {
    var picked = look.color;
    final saved = await showColorPicker(
      context,
      color: look.color,
      onColorChanged: (color) => picked = color,
    );
    if (saved != true || !mounted) return;
    _onChange((current) => current.copyWith(color: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<DiaryNotebookBloc, DiaryNotebookState>(
      listenWhen: (previous, current) =>
          current.saveFailureCount != previous.saveFailureCount,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed)),
        );
      },
      child: BlocBuilder<DiaryNotebookBloc, DiaryNotebookState>(
        builder: (context, state) {
          final look = _look(state);
          final swatches = look.template.recommendedColors;
          final isCustom = !swatches.any(
            (color) => color.toARGB32() == look.color.toARGB32(),
          );
          final specs = _covers.isEmpty
              ? [
                  for (final image in PaperNotebookCoverImage.bundled)
                    PaperNotebookCoverSpec(
                      image: image,
                      zh: image.id,
                      en: image.id,
                    ),
                ]
              : _covers;
          final locale = Localizations.localeOf(context);
          return AppScaffold(
            appBar: AppBar(title: Text(l10n.diaryEditNotebook)),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    itemCount: PaperNotebookCoverTemplate.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final template = PaperNotebookCoverTemplate.values[index];
                      final slide = look.copyWith(
                        template: template,
                        color: _colorFor(look, template),
                      );
                      return _CoverSlide(
                        year: widget.year,
                        look: slide,
                        title: l10n.diaryBook,
                        selected: look.template == template,
                        onTap: () => _onChange(
                          (current) => current.copyWith(
                            template: template,
                            color: _colorFor(current, template),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _SectionLabel(l10n.diaryCoverImage),
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    itemCount: specs.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final spec = index == 0 ? null : specs[index - 1];
                      final image = spec?.image ?? PaperNotebookCoverImage.none;
                      return _CoverImageThumb(
                        image: image,
                        color: look.color,
                        selected: look.coverImage == image,
                        label: spec?.labelFor(locale) ?? l10n.diaryTextureNone,
                        onTap: () => _onChange(
                          (current) => current.copyWith(coverImage: image),
                        ),
                      );
                    },
                  ),
                ),
                _SectionLabel(l10n.diaryCoverColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final color in swatches)
                        _ColorDot(
                          color: color,
                          selected: look.color.toARGB32() == color.toARGB32(),
                          onTap: () => _onChange(
                            (current) => current.copyWith(color: color),
                          ),
                        ),
                      _ColorDot(
                        color: look.color,
                        selected: isCustom,
                        outlined: true,
                        onTap: () => _pickCustomColor(look),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
                  child: PullDownButton(
                    itemBuilder: (context) => [
                      for (final texture in PaperNotebookCoverTexture.values)
                        PullDownMenuItem.selectable(
                          title: _textureLabel(l10n, texture),
                          selected: look.texture == texture,
                          onTap: () => _onChange(
                            (current) => current.copyWith(texture: texture),
                          ),
                        ),
                    ],
                    buttonBuilder: (context, showMenu) => ListTile(
                      minVerticalPadding: 0,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      leading: const Icon(Icons.texture),
                      title: Text(l10n.diaryCoverTexture),
                      trailing: Text(_textureLabel(l10n, look.texture)),
                      onTap: showMenu,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
                  child: PullDownButton(
                    itemBuilder: (context) => [
                      for (final pattern in PaperNotebookPattern.values)
                        PullDownMenuItem.selectable(
                          title: _paperLabel(l10n, pattern),
                          selected: look.paperPattern == pattern,
                          onTap: () => _onChange(
                            (current) =>
                                current.copyWith(paperPattern: pattern),
                          ),
                        ),
                    ],
                    buttonBuilder: (context, showMenu) => ListTile(
                      minVerticalPadding: 0,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      leading: const Icon(Icons.grid_on_outlined),
                      title: Text(l10n.diaryPaperPattern),
                      trailing: Text(_paperLabel(l10n, look.paperPattern)),
                      onTap: showMenu,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _textureLabel(AppLocalizations l10n, PaperNotebookCoverTexture texture) {
  return switch (texture) {
    PaperNotebookCoverTexture.none => l10n.diaryTextureNone,
    PaperNotebookCoverTexture.leather => l10n.diaryTextureLeather,
    PaperNotebookCoverTexture.kraft => l10n.diaryTextureKraft,
    PaperNotebookCoverTexture.cloth => l10n.diaryTextureCloth,
    PaperNotebookCoverTexture.smooth => l10n.diaryTextureSmooth,
  };
}

String _paperLabel(AppLocalizations l10n, PaperNotebookPattern pattern) {
  return switch (pattern) {
    PaperNotebookPattern.dots => l10n.diaryPaperDots,
    PaperNotebookPattern.grid => l10n.diaryPaperGrid,
    PaperNotebookPattern.solid => l10n.diaryPaperSolid,
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CoverSlide extends StatelessWidget {
  const _CoverSlide({
    required this.year,
    required this.look,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final int year;
  final DiaryNotebookLook look;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const format = NotebookFormat.defaults;
              final fitted = format.fitScale(constraints.biggest);
              final coverW = format.frontCoverWidth * fitted;
              final coverH = format.frontCoverHeight * fitted;
              final zoom = coverW < 1 || coverH < 1
                  ? 1.0
                  : math.min(
                          constraints.maxWidth / coverW,
                          constraints.maxHeight / coverH,
                        ) *
                        0.86;
              return ClipRect(
                child: Transform.scale(
                  scale: zoom,
                  child: IgnorePointer(
                    child: PaperNotebook(
                      coverGesturesEnabled: false,
                      gesturesEnabled: false,
                      pageCount: 1,
                      paperPattern: look.paperPattern,
                      theme: look.theme(year: year, title: title),
                      pageBuilder: (_, _) => const SizedBox.expand(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CoverImageThumb extends StatelessWidget {
  const _CoverImageThumb({
    required this.image,
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final PaperNotebookCoverImage image;
  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = image.resized(width: 28, height: 40);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.black.withValues(alpha: 0.12),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: thumb == null
                ? ColoredBox(
                    color: color,
                    child: const SizedBox.expand(),
                  )
                : Image(
                    image: thumb,
                    fit: BoxFit.cover,
                    width: 28,
                    height: 40,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: color,
                      child: const SizedBox.expand(),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    this.outlined = false,
  });

  final Color color;
  final bool selected;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.black.withValues(alpha: 0.12),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: outlined
            ? const Icon(Icons.colorize, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
