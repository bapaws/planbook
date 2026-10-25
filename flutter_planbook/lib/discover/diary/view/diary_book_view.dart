import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/model/app_image_provider.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_page_navigation.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_reader_scope.dart';
import 'package:flutter_planbook/discover/diary/bloc/diary_book_bloc.dart';
import 'package:flutter_planbook/discover/diary/bloc/diary_notebook_bloc.dart';
import 'package:flutter_planbook/discover/diary/model/diary_book_document.dart';
import 'package:flutter_planbook/discover/diary/model/diary_image_metrics.dart';
import 'package:flutter_planbook/discover/diary/view/diary_book_leaf.dart';
import 'package:flutter_planbook/discover/diary/view/diary_notebook_theme.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/gallery/view/note_gallery_calendar_view.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:paper_notebook/paper_notebook.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

Future<void> _createDiaryEntry(BuildContext context) async {
  final limitReached = await context
      .read<AppPurchasesBloc>()
      .isNoteLimitReached();
  if (!context.mounted) return;
  if (limitReached) {
    await context.router.push(const AppPurchasesRoute());
    return;
  }
  await context.router.push(NoteNewRoute());
}

class DiaryBookView extends StatelessWidget {
  const DiaryBookView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DiaryBookBloc(notesRepository: context.read())
            ..add(const DiaryBookRequested()),
      child: const _DiaryBookView(),
    );
  }
}

class _DiaryBookView extends StatefulWidget {
  const _DiaryBookView();

  @override
  State<_DiaryBookView> createState() => _DiaryBookViewState();
}

class _DiaryBookViewState extends State<_DiaryBookView> {
  final _metrics = DiaryImageMetrics();
  var _pagination = DiaryBookPaginationCache();
  final _preparing = <String>{};
  List<NoteEntity>? _notes;
  int? _year;
  TextScaler? _scaler;
  TextDirection? _direction;
  late DiaryBookDocument _document;
  String? _readingNoteId;
  var _revision = 0;
  var _documentRevision = -1;
  var _hasShownPages = false;

  @override
  void reassemble() {
    super.reassemble();
    // 热重载会保留 State；模板代码更新时必须重新分页，不能复用旧的纸页。
    _pagination = DiaryBookPaginationCache();
    _documentRevision = -1;
  }

  void _prepare(NoteEntity note) {
    final photos = diaryPhotos(note);
    if (_metrics.isReady(photos)) return;
    final signature = '${note.id}:${photos.join('\n')}';
    if (!_preparing.add(signature)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final configuration = createLocalImageConfiguration(context);
      await _metrics.prepare(
        photos,
        providerForPath: (path) => imageProviderForPath(
          path,
          assetsRepository: path.startsWith('assets/')
              ? null
              : context.read<AssetsRepository>(),
        ),
        configuration: configuration,
      );
      if (!mounted) return;
      _preparing.remove(signature);
      setState(() => _revision++);
    });
  }

  @override
  void dispose() {
    _metrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notebook = _notebookBloc(context);
    if (notebook == null) {
      return BlocBuilder<DiaryBookBloc, DiaryBookState>(
        builder: (context, state) => _pages(context, state, year: null),
      );
    }
    return BlocBuilder<DiaryNotebookBloc, DiaryNotebookState>(
      bloc: notebook,
      builder: (context, notebookState) {
        return BlocBuilder<DiaryBookBloc, DiaryBookState>(
          builder: (context, state) => _pages(
            context,
            state,
            year: notebookState.selectedYear,
            showCalendar: notebookState.isCalendarExpanded,
          ),
        );
      },
    );
  }

  Widget _pages(
    BuildContext context,
    DiaryBookState state, {
    required int? year,
    bool showCalendar = false,
  }) {
    final notes = year == null
        ? state.notes
        : [
            for (final note in state.notes)
              if (note.createdAt.year == year) note,
          ];
    var current = notes.indexWhere((note) => note.id == _readingNoteId);
    if (current < 0) current = 0;
    if (notes.isNotEmpty) {
      _prepare(notes[current]);
      if (current + 1 < notes.length) _prepare(notes[current + 1]);
    }
    final firstReady =
        notes.isEmpty || _metrics.isReady(diaryPhotos(notes[current]));
    if (notes.isEmpty) _hasShownPages = false;
    if (firstReady && notes.isNotEmpty) _hasShownPages = true;
    final waitingForFirst = !_hasShownPages && !firstReady;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    if (_notes != state.notes ||
        _year != year ||
        _scaler != scaler ||
        _direction != direction ||
        _documentRevision != _revision) {
      _notes = state.notes;
      _year = year;
      _scaler = scaler;
      _direction = direction;
      _documentRevision = _revision;
      _document = _pagination.paginate(
        notes,
        imageAspectRatios: _metrics.ratios,
        textScaler: scaler,
        textDirection: direction,
      );
    }
    final reader = _DiaryReader(
      document: waitingForFirst ? const DiaryBookDocument([]) : _document,
      status: waitingForFirst ? PageStatus.loading : state.status,
      onRetry: () =>
          context.read<DiaryBookBloc>().add(const DiaryBookRequested()),
      onNoteRead: (id) {
        if (_readingNoteId == id) return;
        setState(() => _readingNoteId = id);
      },
    );
    if (!showCalendar || year == null) return reader;
    return Stack(
      children: [
        reader,
        NoteGalleryCalendarView(
          date: Jiffy.parseFromDateTime(DateTime(year)),
          onDateSelected: (date) {
            context.read<DiaryNotebookBloc>().add(
              DiaryNotebookYearChanged(date.year),
            );
          },
        ),
      ],
    );
  }

  DiaryNotebookBloc? _notebookBloc(BuildContext context) {
    try {
      return context.read<DiaryNotebookBloc>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

class _DiaryReader extends StatefulWidget {
  const _DiaryReader({
    required this.document,
    required this.status,
    required this.onRetry,
    required this.onNoteRead,
  });

  final DiaryBookDocument document;
  final PageStatus status;
  final VoidCallback onRetry;
  final ValueChanged<String> onNoteRead;

  @override
  State<_DiaryReader> createState() => _DiaryReaderState();
}

class _DiaryReaderState extends State<_DiaryReader> {
  final _controller = PaperNotebookController();
  bool _editing = false;
  Timer? _playback;
  final GlobalKey _bookKey = GlobalKey();
  NotebookReaderController? _reader;
  late DiaryBookDocument _document;
  var _initialIndex = 0;
  var _adoptionScheduled = false;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _controller.addListener(_adoptWhenIdle);
  }

  void _adoptWhenIdle() {
    if (_controller.isAnimating ||
        _document == widget.document ||
        _adoptionScheduled) {
      return;
    }
    _adoptionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adoptionScheduled = false;
      if (!mounted || _controller.isAnimating || _document == widget.document) {
        return;
      }
      final pages = _document.pages;
      final index = _controller.index.clamp(
        0,
        pages.isEmpty ? 0 : pages.length - 1,
      );
      final anchor = pages.isEmpty ? null : pages[index];
      final next = widget.document;
      _initialIndex = next.indexForAnchor(anchor, fallback: index);
      setState(() => _document = next);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _document == next) _controller.jumpTo(_initialIndex);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reader = NotebookReaderScope.maybeOf(context);
    if (reader == _reader) return;
    _reader?.detach(this);
    _reader = reader;
    reader?.attach(
      this,
      open: _controller.openCover,
      close: () async {
        await reader.waitForIdle(_controller, () => _controller.isAnimating);
        if (mounted) await _controller.closeCover();
      },
      coverRect: () => notebookDescendantRect(
        _bookKey.currentContext,
        PaperNotebook.frontCoverKey,
      ),
    );
    reader?.bindEdit(this, _edit);
  }

  @override
  void didUpdateWidget(covariant _DiaryReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _adoptWhenIdle();
  }

  @override
  void dispose() {
    _playback?.cancel();
    _reader?.detach(this);
    _controller.removeListener(_adoptWhenIdle);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play(Jiffy from, Jiffy to) async {
    _playback?.cancel();
    final start = from.startOf(Unit.day);
    final end = to.endOf(Unit.day);
    final pages = _document.pages;
    final indexes = <int>[
      for (var i = 0; i < pages.length; i++)
        if (!pages[i].note.createdAt.isBefore(start) &&
            !pages[i].note.createdAt.isAfter(end))
          i,
    ];
    if (indexes.isEmpty) return;
    await _controller.animateTo(indexes.first);
    if (!mounted || indexes.length == 1) return;
    var step = 1;
    _playback = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || step >= indexes.length) {
        timer.cancel();
        return;
      }
      final index = indexes[step];
      step += 1;
      unawaited(_controller.animateTo(index));
    });
  }

  Future<void> _edit() async {
    if (_editing || _document.pages.isEmpty) return;
    _editing = true;
    try {
      final note = _document.pages[_controller.index].note;
      // 重新获取带标签的完整实体，避免保存时丢失日记原有标签。
      final entity = await context.read<NotesRepository>().getNoteEntityById(
        note.id,
      );
      if (!mounted || entity == null) return;
      await context.router.push(NoteNewRoute(initialNote: entity));
    } finally {
      _editing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = _document.pages;
    final body = SafeArea(
      top: false,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: NotebookPageNavigation.bookReserve(context),
            ),
            child: DiaryNotebookThemeBuilder(
              builder: (year, look) => PaperNotebook(
                key: _bookKey,
                controller: _controller,
                initialIndex: _initialIndex,
                coverClosed: _reader != null,
                // null 让引擎只在首尾合书；true 会把每一次翻页都当成合书。
                closesCoverOnBack: _reader == null ? false : null,
                closesCoverOnForward: _reader == null ? false : null,
                onCoverClosed: () => _reader?.onCoverClosed?.call(),
                paperPattern: look.paperPattern,
                theme: look.theme(year: year, title: l10n.diaryBook),
                pageCount: pages.isEmpty ? 1 : pages.length,
                onIndexChanged: (index) {
                  if (pages.isNotEmpty) {
                    widget.onNoteRead(pages[index].note.id);
                  }
                },
                pageBuilder: (context, index) {
                  if (pages.isEmpty) {
                    return _DiaryEmptyLeaf(
                      status: widget.status,
                      onRetry: widget.onRetry,
                    );
                  }
                  final page = pages[index.clamp(0, pages.length - 1)];
                  final entryCount = pages
                      .where((item) => item.note.id == page.note.id)
                      .length;
                  return DiaryBookLeaf(
                    page: page,
                    number: index.clamp(0, pages.length - 1) + 1,
                    entryCount: entryCount,
                  );
                },
              ),
            ),
          ),
          NotebookPageNavigation(
            child: NotebookReaderChrome(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: l10n.diaryBookPreviousPage,
                      onPressed:
                          _controller.index > 0 && !_controller.isAnimating
                          ? _controller.previousPage
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${pages.isEmpty ? 0 : _controller.index + 1}'
                      ' / ${pages.length}',
                    ),
                    IconButton(
                      tooltip: l10n.diaryBookNextPage,
                      onPressed:
                          _controller.index < pages.length - 1 &&
                              !_controller.isAnimating
                          ? _controller.nextPage
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (_discoverBloc(context) == null) return body;
    return BlocListener<RootDiscoverBloc, RootDiscoverState>(
      listenWhen: (previous, current) =>
          previous.autoPlayCount != current.autoPlayCount,
      listener: (context, state) async {
        final result = await context.router.push<Map<String, dynamic>>(
          const DiscoverJournalPlayRoute(),
        );
        if (!mounted || result == null) return;
        final from = result['from'];
        final to = result['to'];
        if (from is! Jiffy || to is! Jiffy) return;
        await _play(from, to);
      },
      child: body,
    );
  }

  RootDiscoverBloc? _discoverBloc(BuildContext context) {
    try {
      return context.read<RootDiscoverBloc>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

/// 空本子也有可开合的封面，加载和空态放在纸页内。
class _DiaryEmptyLeaf extends StatelessWidget {
  const _DiaryEmptyLeaf({required this.status, required this.onRetry});

  final PageStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == PageStatus.initial ||
                    status == PageStatus.loading)
                  const CircularProgressIndicator()
                else ...[
                  const Icon(Icons.auto_stories_outlined, size: 56),
                  const SizedBox(height: 24),
                  Text(
                    status == PageStatus.failure
                        ? l10n.diaryBookLoadFailure
                        : l10n.diaryBookEmptyTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (status != PageStatus.failure)
                    Text(l10n.diaryBookEmptyBody, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                    onPressed: status == PageStatus.failure
                        ? onRetry
                        : () => _createDiaryEntry(context),
                    child: Text(
                      status == PageStatus.failure
                          ? l10n.diaryBookRetry
                          : l10n.newNote,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
