import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/app_image_provider.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/discover/diary/bloc/diary_book_bloc.dart';
import 'package:flutter_planbook/discover/diary/bloc/diary_notebook_bloc.dart';
import 'package:flutter_planbook/discover/diary/model/diary_book_document.dart';
import 'package:flutter_planbook/discover/diary/model/diary_image_metrics.dart';
import 'package:flutter_planbook/discover/diary/view/diary_book_leaf.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:paper_notebook/paper_notebook.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:planbook_core/app/app_image_saver.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:share_plus/share_plus.dart';

/// 只保留某一自然年里写下的日记。
List<NoteEntity> diaryNotesForYear(Iterable<NoteEntity> notes, int year) {
  return [
    for (final note in notes)
      if (note.createdAt.year == year) note,
  ];
}

@RoutePage()
class DiaryExportPage extends StatelessWidget {
  const DiaryExportPage({this.year, super.key});

  /// 从日记本带入的年份。页面列出这一年的全部纸页。
  final int? year;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DiaryBookBloc(notesRepository: context.read())
            ..add(const DiaryBookRequested()),
      child: _DiaryExportView(year: year ?? DateTime.now().year),
    );
  }
}

class _DiaryExportView extends StatefulWidget {
  const _DiaryExportView({required this.year});

  final int year;

  @override
  State<_DiaryExportView> createState() => _DiaryExportViewState();
}

class _DiaryExportViewState extends State<_DiaryExportView> {
  final GlobalKey _boundaryKey = GlobalKey();
  final GlobalKey _pdfButtonKey = GlobalKey();
  final Set<String> _selected = {};
  DiaryBookDocument? _document;
  var _captureIndex = 0;
  var _preparing = true;
  var _signature = '';
  var _generation = 0;
  var _selectionReady = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final book = context.watch<DiaryBookBloc>().state;
    final paperPattern = context
        .select<DiaryNotebookBloc, PaperNotebookPattern>(
          (bloc) => bloc.state.lookFor(widget.year).paperPattern,
        );
    final notes = diaryNotesForYear(book.notes, widget.year);
    _schedule(book.status, notes);
    final pages = _document?.pages ?? const <DiaryBookPage>[];
    final counts = _entryCounts(pages);
    final selectedIndexes = _selectedIndexes(pages);
    final capture = pages.isEmpty
        ? null
        : pages[_captureIndex.clamp(0, pages.length - 1)];
    final canExport = !_preparing && selectedIndexes.isNotEmpty;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.diaryExportTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _DiaryExportShortcut(
                  label: l10n.selectAll,
                  onPressed: pages.isEmpty
                      ? null
                      : () => setState(() {
                          _selected.addAll(pages.map((page) => page.identity));
                        }),
                ),
                const SizedBox(width: 4),
                _DiaryExportShortcut(
                  label: l10n.unselectAll,
                  onPressed: _selected.isEmpty
                      ? null
                      : () => setState(_selected.clear),
                ),
                const Spacer(),
                Text(
                  '${_selected.length}/${pages.length}',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (capture != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    width: kDiaryPageSize.width,
                    height: kDiaryPageSize.height,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: DiaryBookLeaf(
                        page: capture,
                        number: _captureIndex.clamp(0, pages.length - 1) + 1,
                        entryCount: counts[capture.note.id] ?? 1,
                        paperPattern: paperPattern,
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: ColoredBox(
                    color: theme.colorScheme.surface,
                    child: _gallery(
                      context,
                      pages: pages,
                      counts: counts,
                      paperPattern: paperPattern,
                      loading: book.status != PageStatus.failure && _preparing,
                      failed: book.status == PageStatus.failure,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: CupertinoButton(
                    key: _pdfButtonKey,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.fromHeight(kToolbarHeight),
                    color: theme.colorScheme.secondaryContainer,
                    onPressed: canExport ? _onPdf : null,
                    child: Text(
                      l10n.journalExportExportPdf,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.fromHeight(kToolbarHeight),
                    color: theme.colorScheme.primaryContainer,
                    onPressed: canExport ? _onImages : null,
                    child: Text(
                      l10n.journalExportExportImages,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
        ],
      ),
    );
  }

  Widget _gallery(
    BuildContext context, {
    required List<DiaryBookPage> pages,
    required Map<String, int> counts,
    required PaperNotebookPattern paperPattern,
    required bool loading,
    required bool failed,
  }) {
    if (pages.isEmpty) {
      final l10n = context.l10n;
      return Center(
        child: loading
            ? const CircularProgressIndicator()
            : Text(
                failed ? l10n.diaryBookLoadFailure : l10n.diaryExportEmpty,
                textAlign: TextAlign.center,
              ),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: pages.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final page = pages[index];
        return AspectRatio(
          aspectRatio: kDiaryPageSize.width / kDiaryPageSize.height,
          child: _DiaryExportThumb(
            selected: _selected.contains(page.identity),
            onTap: () => _toggle(page.identity),
            child: DiaryBookLeaf(
              page: page,
              number: index + 1,
              entryCount: counts[page.note.id] ?? 1,
              paperPattern: paperPattern,
            ),
          ),
        );
      },
    );
  }

  void _toggle(String identity) {
    setState(() {
      if (!_selected.add(identity)) _selected.remove(identity);
    });
  }

  Map<String, int> _entryCounts(List<DiaryBookPage> pages) {
    final counts = <String, int>{};
    for (final page in pages) {
      counts[page.note.id] = (counts[page.note.id] ?? 0) + 1;
    }
    return counts;
  }

  List<int> _selectedIndexes(List<DiaryBookPage> pages) {
    return [
      for (var index = 0; index < pages.length; index++)
        if (_selected.contains(pages[index].identity)) index,
    ];
  }

  void _schedule(PageStatus status, List<NoteEntity> notes) {
    if (status != PageStatus.success) return;
    final signature = StringBuffer()
      ..write(widget.year)
      ..write(':')
      ..write(MediaQuery.textScalerOf(context))
      ..write(':')
      ..write(Directionality.of(context).name);
    for (final note in notes) {
      signature
        ..write('|')
        ..write(note.id)
        ..write(':')
        ..write(note.title)
        ..write(':')
        ..write(note.content)
        ..write(':')
        ..write(note.images.join(','));
    }
    final next = signature.toString();
    if (next == _signature) return;
    _signature = next;
    _document = null;
    _preparing = true;
    final generation = ++_generation;
    final snapshot = notes;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_paginate(generation, snapshot));
    });
  }

  Future<void> _paginate(int generation, List<NoteEntity> notes) async {
    final metrics = DiaryImageMetrics();
    try {
      final photos = notes.expand(diaryPhotos);
      if (photos.isNotEmpty) {
        final repository = context.read<AssetsRepository>();
        await metrics.prepare(
          photos,
          providerForPath: (path) => imageProviderForPath(
            path,
            assetsRepository: path.startsWith('assets/') ? null : repository,
          ),
          configuration: createLocalImageConfiguration(context),
        );
      }
      if (!mounted || generation != _generation) return;
      final document = DiaryBookDocument.fromNotes(
        notes,
        imageAspectRatios: metrics.ratios,
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      );
      final ids = document.pages.map((page) => page.identity).toSet();
      setState(() {
        _document = document;
        _captureIndex = 0;
        _preparing = false;
        if (!_selectionReady) {
          _selected
            ..clear()
            ..addAll(ids);
          _selectionReady = ids.isNotEmpty;
        } else {
          _selected.removeWhere((id) => !ids.contains(id));
        }
      });
    } finally {
      metrics.dispose();
    }
  }

  Future<void> _onPdf() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final indexes = _selectedIndexes(_document?.pages ?? const []);
    await EasyLoading.show(status: l10n.journalExportExporting);
    if (!mounted) return;
    try {
      final pngs = await _captureAll(indexes);
      if (pngs.isEmpty) {
        await EasyLoading.dismiss();
        if (mounted) await EasyLoading.showError(l10n.diaryExportEmpty);
        return;
      }
      final doc = pw.Document();
      for (final png in pngs) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(png))),
          ),
        );
      }
      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/planbook_diary_$stamp.pdf');
      await file.writeAsBytes(bytes);
      await EasyLoading.dismiss();
      if (!mounted) return;
      final shareBox =
          _pdfButtonKey.currentContext!.findRenderObject()! as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: l10n.diaryExportTitle,
          sharePositionOrigin:
              shareBox.localToGlobal(Offset.zero) & shareBox.size,
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.journalExportSuccess)),
      );
    } on Object {
      await EasyLoading.dismiss();
      if (mounted) await EasyLoading.showError(l10n.journalExportFailed);
    }
  }

  Future<void> _onImages() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final pages = _document?.pages ?? const <DiaryBookPage>[];
    final indexes = _selectedIndexes(pages);
    await EasyLoading.showProgress(
      0,
      status: l10n.journalExportSavingImages(0, indexes.length),
    );
    if (!mounted) {
      await EasyLoading.dismiss();
      return;
    }
    try {
      if (indexes.isEmpty) {
        await EasyLoading.dismiss();
        if (mounted) await EasyLoading.showError(l10n.diaryExportEmpty);
        return;
      }
      var saved = 0;
      for (final index in indexes) {
        final png = await _capturePage(index);
        if (!mounted) {
          await EasyLoading.dismiss();
          return;
        }
        if (png == null) continue;
        final result = await AppImageSaver.saveImage(
          png,
          fileName: _filename(pages[index], index + 1),
        );
        if (!result.isSuccess) continue;
        saved++;
        await EasyLoading.showProgress(
          saved / indexes.length,
          status: l10n.journalExportSavingImages(saved, indexes.length),
        );
      }
      await EasyLoading.dismiss();
      if (!mounted) return;
      if (saved <= 0) {
        await EasyLoading.showError(l10n.saveFailed);
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.journalExportImagesSaved(saved))),
      );
    } on Object {
      await EasyLoading.dismiss();
      if (mounted) await EasyLoading.showError(l10n.saveFailed);
    }
  }

  Future<List<Uint8List>> _captureAll(List<int> indexes) async {
    final pngs = <Uint8List>[];
    for (final index in indexes) {
      final png = await _capturePage(index);
      if (!mounted) return pngs;
      if (png != null) pngs.add(png);
    }
    if (mounted) setState(() => _captureIndex = 0);
    return pngs;
  }

  Future<Uint8List?> _capturePage(int index) async {
    final pages = _document?.pages;
    if (pages == null || index < 0 || index >= pages.length) return null;
    setState(() => _captureIndex = index);
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return null;
    final repository = context.read<AssetsRepository>();
    for (final path in pages[index].images) {
      try {
        await precacheImage(
          imageProviderForPath(
            path,
            assetsRepository: path.startsWith('assets/') ? null : repository,
          ),
          context,
        ).timeout(const Duration(seconds: 4));
      } on Object {
        // 缺图时仍导出带占位的这一页。
      }
    }
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 48));
    if (!mounted) return null;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  String _filename(DiaryBookPage page, int number) {
    final day = page.note.createdAt.format(pattern: 'yyyy-MM-dd');
    return 'Diary_${day}_${number.toString().padLeft(2, '0')}';
  }
}

/// 和计划本导出页里的 Today 一样：浅色小按钮，字号用 labelMedium。
class _DiaryExportShortcut extends StatelessWidget {
  const _DiaryExportShortcut({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoButton.tinted(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _DiaryExportThumb extends StatelessWidget {
  const _DiaryExportThumb({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: selected ? 3 : 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              top: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
