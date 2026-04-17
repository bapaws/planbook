import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/discover/journal/model/journal_date.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_cover.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:planbook_core/app/app_image_saver.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 供导出页持有，用于触发横向日记视图的 PDF / 图片导出（由 [DiscoverJournalHorizontalView] 在 mount 时挂载）。
class DiscoverJournalHorizontalExportController {
  _DiscoverJournalHorizontalViewState? _host;

  // 由 View State 注册，非典型 setter 语义
  // ignore: use_setters_to_change_properties
  void _attach(_DiscoverJournalHorizontalViewState host) {
    _host = host;
  }

  void _detach(_DiscoverJournalHorizontalViewState host) {
    if (_host == host) _host = null;
  }

  /// 将 [start]、[end] 区间内每日的左右半页渲染为 PDF（每天 2 页）。
  Future<File?> exportJournalPdf({
    required BuildContext context,
    required Jiffy start,
    required Jiffy end,
  }) async {
    final host = _host;
    if (host == null) return null;
    return host.exportJournalPdf(context: context, start: start, end: end);
  }

  /// 仅导出当前可见的半页到相册（免费用户）。
  Future<bool> exportCurrentPageImage({required BuildContext context}) async {
    final host = _host;
    if (host == null) return false;
    return host.exportCurrentPageImage(context: context);
  }

  /// 将区间内每日左右半页逐张保存到相册；返回成功保存的张数。
  Future<int> exportJournalImagesBatch({
    required BuildContext context,
    required Jiffy start,
    required Jiffy end,
    void Function(int saved, int total)? onProgress,
  }) async {
    final host = _host;
    if (host == null) return 0;
    return host.exportJournalImagesBatch(
      context: context,
      start: start,
      end: end,
      onProgress: onProgress,
    );
  }
}

class DiscoverJournalHorizontalView extends StatefulWidget {
  const DiscoverJournalHorizontalView({
    super.key,
    this.listenToRootBlocs = true,
    this.bottomOverlayReserve = kRootBottomBarHeight,
    this.exportController,
  });

  /// 为 false 时不监听「保存图片 / 自动播放」等根级 Bloc（导出页嵌入场景）。
  final bool listenToRootBlocs;

  /// 预览区底部预留高度（发现页为底部 Tab；导出页可设为 0）。
  final double bottomOverlayReserve;

  final DiscoverJournalHorizontalExportController? exportController;

  @override
  State<DiscoverJournalHorizontalView> createState() =>
      _DiscoverJournalHorizontalViewState();
}

class _DiscoverJournalHorizontalViewState
    extends State<DiscoverJournalHorizontalView> {
  PageController? _pageController;
  int? _pageControllerYear;

  /// 程序化滚动（由 BlocListener 触发）时置为 true，避免 onPageChanged 把日期改回当前页
  bool _isAnimating = false;

  /// 自动播放中，listener 不执行 animateToPage，由 _play 的 timer 负责
  bool _isPlaying = false;

  /// PDF 导出过程中跳过 onPageChanged 与日期同步 listener 的干扰
  bool _isExporting = false;

  /// 每页一个 GlobalKey，截图时用当前页 index 取 boundary，无需 setState，避免两次刷新。
  /// 仅保留当前页前后各 [_boundaryKeyWindow] 个 index，避免积累大量 key。
  static const int _boundaryKeyWindow = 3;
  final Map<int, GlobalKey> _boundaryKeys = {};

  GlobalKey _boundaryKeyForIndex(int index) {
    final key = _boundaryKeys.putIfAbsent(index, GlobalKey.new);
    final c = _pageController;
    if (c == null || !c.hasClients) return key;
    final current = c.page?.round() ?? 0;
    for (final i in _boundaryKeys.keys.toList()) {
      // 正在构建的 index 不得在此轮回收：动画过程中 current 可能尚未到达该页，
      // 否则会刚 putIfAbsent 就被移除，_capturePagePng 用 map 查不到 boundary，
      // 表现为左半页保存失败、只剩右半页等现象。
      if (i == index) continue;
      if ((i - current).abs() > _boundaryKeyWindow) _boundaryKeys.remove(i);
    }
    return key;
  }

  PageController _controllerForYear(JournalDate focus) {
    final year = focus.year;
    if (_pageControllerYear == year && _pageController != null) {
      return _pageController!;
    }
    _pageController?.dispose();
    _pageControllerYear = year;
    _boundaryKeys.clear();
    final page = _pageIndexForDate(focus);
    _pageController = PageController(initialPage: page);
    return _pageController!;
  }

  /// 当年的总页数（封面 + 左右半页 + 封底）。
  int _itemCountForYear(int year) {
    final startOfYear = Jiffy.parseFromList([year]);
    final daysInYear = startOfYear
        .add(years: 1)
        .diff(startOfYear, unit: Unit.day)
        .toInt();
    return daysInYear * 2 + 2;
  }

  /// 将 [JournalDate] 映射到 PageView 中的页索引。日子默认落在左半页。
  int _pageIndexForDate(JournalDate date) {
    if (date.isCoverPage) return 0;
    if (date.isBackCoverPage) return date.daysInYear * 2 + 1;
    // JournalDate.pageIndex.left = dayIndex * 2，加 1 跳过封面
    return 1 + date.pageIndex.left;
  }

  /// PageView 页索引反查对应的日期（始终以当前控制器所在年份为基准）。
  JournalDate _dateFromPageIndex(int index, int year) {
    final backCoverIndex = _itemCountForYear(year) - 1;
    if (index <= 0) return JournalDate.fromYear(year);
    if (index >= backCoverIndex) {
      return JournalDate(year: year, month: 12, day: null);
    }
    final dayIdx = (index - 1) ~/ 2;
    final startOfYear = Jiffy.parseFromList([year]);
    return JournalDate.fromJiffy(startOfYear.add(days: dayIdx));
  }

  @override
  void initState() {
    super.initState();
    widget.exportController?._attach(this);
  }

  @override
  void dispose() {
    widget.exportController?._detach(this);
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Timer? _timer;

  Future<Uint8List?> _capturePagePng(int pageIndex, double pixelRatio) async {
    final boundary =
        _boundaryKeys[pageIndex]?.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// 导出区间内每日左右页为 PDF；依赖当前 [DiscoverJournalBloc] 年份与 [PageController] 同步。
  /// 开始的年份会追加一张封面，结束的年份会追加一张封底。
  Future<File?> exportJournalPdf({
    required BuildContext context,
    required Jiffy start,
    required Jiffy end,
  }) async {
    final normalizedStart = start.startOf(Unit.day);
    final normalizedEnd = end.startOf(Unit.day);
    if (normalizedEnd.isBefore(normalizedStart)) return null;

    final totalDays =
        normalizedEnd.diff(normalizedStart, unit: Unit.day).toInt() + 1;
    final doc = pw.Document();
    const exportPixelRatio = 1.75;

    if (!mounted) return null;
    _isExporting = true;
    final journalBloc = context.read<DiscoverJournalBloc>();

    void addPng(Uint8List png) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Image(pw.MemoryImage(png)),
          ),
        ),
      );
    }

    try {
      // 1. 开始年份的封面
      final coverPng = await _goToAndCapture(
        journalBloc: journalBloc,
        target: JournalDate.fromYear(normalizedStart.year),
        pixelRatio: exportPixelRatio,
      );
      if (coverPng != null) addPng(coverPng);

      // 2. 每日左右半页
      for (var i = 0; i < totalDays; i++) {
        if (!mounted) return null;
        final d = normalizedStart.add(days: i);

        for (var half = 0; half < 2; half++) {
          if (!mounted) return null;
          final png = await _goToAndCapture(
            journalBloc: journalBloc,
            target: JournalDate.fromJiffy(d),
            halfOffset: half,
            pixelRatio: exportPixelRatio,
          );
          if (png != null) addPng(png);
        }
      }

      // 3. 结束年份的封底
      if (mounted) {
        final backCoverPng = await _goToAndCapture(
          journalBloc: journalBloc,
          target: JournalDate(
            year: normalizedEnd.year,
            month: 12,
            day: null,
          ),
          pixelRatio: exportPixelRatio,
        );
        if (backCoverPng != null) addPng(backCoverPng);
      }

      final bytes = await doc.save();
      if (!mounted) return null;
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/planbook_journal_$stamp.pdf');
      await file.writeAsBytes(bytes);
      return file;
    } finally {
      if (mounted) _isExporting = false;
    }
  }

  /// 确保 Bloc 指向 [target]，动画到对应页并截图。
  /// [halfOffset] 仅对日子页生效：0=左半页、1=右半页。
  Future<Uint8List?> _goToAndCapture({
    required DiscoverJournalBloc journalBloc,
    required JournalDate target,
    required double pixelRatio,
    int halfOffset = 0,
  }) async {
    journalBloc.add(DiscoverJournalDateChanged(date: target));
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 16));

    if (!mounted) return null;
    final c = _pageController;
    if (c == null || !c.hasClients) return null;

    var pageIdx = _pageIndexForDate(target);
    if (!target.isCoverPage && !target.isBackCoverPage) {
      pageIdx += halfOffset;
    }

    _isAnimating = true;
    await c.animateToPage(
      pageIdx,
      duration: Durations.medium1,
      curve: Curves.easeInOut,
    );
    _isAnimating = false;

    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 320));

    if (!mounted) return null;
    return _capturePagePng(pageIdx, pixelRatio);
  }

  /// 当前 [PageView] 可见半页写入相册（封面 / 封底 / L / R 区分文件名）。
  Future<bool> exportCurrentPageImage({required BuildContext context}) async {
    if (!mounted) return false;
    final c = _pageController;
    if (c == null || !c.hasClients) return false;

    final page = c.page?.round() ?? 0;
    final journalBloc = context.read<DiscoverJournalBloc>();
    final year = journalBloc.state.date.year;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final png = await _capturePagePng(page, pixelRatio);
    if (png == null) return false;

    final result = await AppImageSaver.saveImage(
      png,
      fileName: _filenameForPage(page, year),
    );
    return result.isSuccess;
  }

  /// 根据 PageView 页索引生成保存到相册时使用的文件名。
  String _filenameForPage(int pageIdx, int year) {
    final date = _dateFromPageIndex(pageIdx, year);
    if (date.isCoverPage) return 'Journal_${year}_Cover';
    if (date.isBackCoverPage) return 'Journal_${year}_BackCover';
    final dateStr =
        '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day!.toString().padLeft(2, '0')}';
    // 封面之后：奇数=左半页、偶数=右半页
    final half = pageIdx.isOdd ? 'L' : 'R';
    return 'Journal_${dateStr}_$half';
  }

  /// 区间内每个半页保存为一张图片；额外在首尾追加封面与封底。
  /// [onProgress] 参数为 (已保存张数, 总张数)。
  Future<int> exportJournalImagesBatch({
    required BuildContext context,
    required Jiffy start,
    required Jiffy end,
    void Function(int saved, int total)? onProgress,
  }) async {
    final normalizedStart = start.startOf(Unit.day);
    final normalizedEnd = end.startOf(Unit.day);
    if (normalizedEnd.isBefore(normalizedStart)) return 0;

    final totalDays =
        normalizedEnd.diff(normalizedStart, unit: Unit.day).toInt() + 1;
    // 每日 2 张 + 封面 + 封底
    final totalImages = totalDays * 2 + 2;
    const exportPixelRatio = 1.75;

    if (!mounted) return 0;
    _isExporting = true;
    final journalBloc = context.read<DiscoverJournalBloc>();
    var saved = 0;
    onProgress?.call(0, totalImages);

    Future<bool> saveOne(Uint8List? png, String fileName) async {
      if (png == null) return false;
      final result = await AppImageSaver.saveImage(png, fileName: fileName);
      return result.isSuccess;
    }

    try {
      // 1. 开始年份的封面
      final coverPng = await _goToAndCapture(
        journalBloc: journalBloc,
        target: JournalDate.fromYear(normalizedStart.year),
        pixelRatio: exportPixelRatio,
      );
      if (await saveOne(coverPng, 'Journal_${normalizedStart.year}_Cover')) {
        saved++;
        onProgress?.call(saved, totalImages);
      }

      // 2. 每日左右半页
      for (var i = 0; i < totalDays; i++) {
        if (!mounted) return saved;
        final d = normalizedStart.add(days: i);
        final dateStr =
            '${d.year}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.date.toString().padLeft(2, '0')}';

        for (var half = 0; half < 2; half++) {
          if (!mounted) return saved;
          final png = await _goToAndCapture(
            journalBloc: journalBloc,
            target: JournalDate.fromJiffy(d),
            halfOffset: half,
            pixelRatio: exportPixelRatio,
          );
          final tag = half == 0 ? 'L' : 'R';
          if (await saveOne(png, 'Journal_${dateStr}_$tag')) {
            saved++;
            onProgress?.call(saved, totalImages);
          }
        }
      }

      // 3. 结束年份的封底
      if (mounted) {
        final backCoverPng = await _goToAndCapture(
          journalBloc: journalBloc,
          target: JournalDate(
            year: normalizedEnd.year,
            month: 12,
            day: null,
          ),
          pixelRatio: exportPixelRatio,
        );
        if (await saveOne(
          backCoverPng,
          'Journal_${normalizedEnd.year}_BackCover',
        )) {
          saved++;
          onProgress?.call(saved, totalImages);
        }
      }
      return saved;
    } finally {
      if (mounted) _isExporting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final screenSize = MediaQuery.of(context).size;
    var pageWidth = (screenSize.width - 32) * 2;
    final widthScale = pageWidth / kDiscoverJournalDailyPageWidth;
    var pageHeight =
        screenSize.height -
        query.padding.vertical -
        widget.bottomOverlayReserve;
    if (pageHeight <= 0) {
      pageHeight = kDiscoverJournalDailyPageHeight * 0.35;
    }
    final heightScale = pageHeight / kDiscoverJournalDailyPageHeight;
    if (widthScale > heightScale) {
      pageWidth = pageWidth * heightScale / widthScale;
    } else {
      pageHeight = pageHeight * widthScale / heightScale;
    }

    final blocConsumer =
        BlocConsumer<DiscoverJournalBloc, DiscoverJournalState>(
          listenWhen: (previous, current) =>
              previous.date != current.date &&
              previous.date.year == current.date.year,
          listener: (context, state) {
            if (_isPlaying || _isExporting) return;

            final journalDate = state.date;
            final c = _pageController;
            if (c == null || !c.hasClients) return;

            final targetPage = _pageIndexForDate(journalDate);
            final currentPage = c.page?.round() ?? 0;
            // 日子页允许左半页 / 右半页任一停留
            final isDayPage =
                !journalDate.isCoverPage && !journalDate.isBackCoverPage;
            if (isDayPage) {
              if (currentPage == targetPage || currentPage == targetPage + 1) {
                return;
              }
            } else if (currentPage == targetPage) {
              return;
            }

            _isAnimating = true;
            c
                .animateToPage(
                  targetPage,
                  duration: Durations.medium1,
                  curve: Curves.easeInOut,
                )
                .whenComplete(() {
                  if (mounted) _isAnimating = false;
                });
          },
          buildWhen: (previous, current) =>
              previous.date.year != current.date.year ||
              previous.coverBackgroundImage != current.coverBackgroundImage ||
              previous.coverColorScheme != current.coverColorScheme,
          builder: (context, state) {
            final controller = _controllerForYear(state.date);
            final itemCount = _itemCountForYear(state.date.year);
            final backCoverIndex = itemCount - 1;
            return SizedBox(
              width: screenSize.width,
              height: pageHeight,
              child: SizedBox(
                width: pageWidth,
                height: pageHeight,
                child: PageView.builder(
                  controller: controller,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    final Widget child;
                    if (index == 0) {
                      child = JournalCover(
                        year: state.date.year,
                        backgroundImage: state.coverBackgroundImage,
                        colorScheme: state.coverColorScheme,
                      );
                    } else if (index == backCoverIndex) {
                      child = JournalBackCover(
                        year: state.date.year,
                        backgroundImage: state.coverBackgroundImage,
                        colorScheme: state.coverColorScheme,
                      );
                    } else {
                      final dayIdx = (index - 1) ~/ 2;
                      final date = state.date.startOfYear.add(days: dayIdx);
                      // 封面之后：奇数=左半页、偶数=右半页
                      child = index.isOdd
                          ? JournalDailyLeftPage(
                              date: date,
                              key: ValueKey(index),
                            )
                          : JournalDailyRightPage(
                              date: date,
                              key: ValueKey(index),
                            );
                    }
                    return FittedBox(
                      child: RepaintBoundary(
                        key: _boundaryKeyForIndex(index),
                        child: child,
                      ),
                    );
                  },
                  onPageChanged: (index) {
                    if (_isAnimating || _isExporting) return;
                    final date = _dateFromPageIndex(index, state.date.year);
                    context.read<DiscoverJournalBloc>().add(
                      DiscoverJournalDateChanged(date: date),
                    );
                  },
                ),
              ),
            );
          },
        );

    if (!widget.listenToRootBlocs) return blocConsumer;

    return MultiBlocListener(
      listeners: [
        BlocListener<RootHomeBloc, RootHomeState>(
          listenWhen: (previous, current) =>
              previous.downloadJournalDayCount !=
              current.downloadJournalDayCount,
          listener: (context, state) {
            _timer?.cancel();
            _timer = null;

            final c = _pageController;
            final page = c?.page?.toInt();
            if (page == null) return;

            final year = context.read<DiscoverJournalBloc>().state.date.year;
            _capture(context, year: year, pageIndex: page);
          },
        ),
        BlocListener<RootDiscoverBloc, RootDiscoverState>(
          listenWhen: (previous, current) =>
              previous.autoPlayCount != current.autoPlayCount,
          listener: (context, state) async {
            final result = await context.router.push<Map<String, dynamic>>(
              const DiscoverJournalPlayRoute(),
            );
            if (result == null) return;

            final from = result['from'];
            final to = result['to'];
            if (from != null && from is Jiffy && to != null && to is Jiffy) {
              await _play(from: from, to: to);
            }
          },
        ),
      ],
      child: blocConsumer,
    );
  }

  Future<void> _capture(
    BuildContext context, {
    required int year,
    required int pageIndex,
  }) async {
    await EasyLoading.show();
    if (!context.mounted) return;

    try {
      final boundary =
          _boundaryKeys[pageIndex]?.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        await EasyLoading.showError(context.l10n.saveFailed);
        return;
      }

      final image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );

      if (!context.mounted) return;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!context.mounted) return;
      if (byteData == null) {
        await EasyLoading.showError(context.l10n.saveFailed);
        return;
      }

      final imageBytes = byteData.buffer.asUint8List();
      final result = await AppImageSaver.saveImage(
        imageBytes,
        fileName: _filenameForPage(pageIndex, year),
      );
      await EasyLoading.dismiss();
      if (!context.mounted) return;

      if (result.isSuccess) {
        await EasyLoading.showSuccess(context.l10n.saveSuccess);
      } else {
        await EasyLoading.showError(context.l10n.saveFailed);
      }
    } on Exception catch (_) {
      await EasyLoading.dismiss();

      if (!context.mounted) return;
      await EasyLoading.showError(context.l10n.saveFailed);
    }
  }

  Future<void> _play({
    required Jiffy from,
    required Jiffy to,
  }) async {
    final startOfYear = from.startOf(Unit.year);
    final fromDay = from.diff(startOfYear, unit: Unit.day).toInt();
    final toDay = to.diff(startOfYear, unit: Unit.day).toInt();
    // 封面占据索引 0，日子页从 1 开始
    final fromPage = 1 + fromDay * 2;
    final toPage = 1 + toDay * 2 + 1;

    if (!mounted) return;
    _isPlaying = true;
    final c = _pageController;
    if (c == null) return;

    context.read<DiscoverJournalBloc>().add(
      DiscoverJournalDateChanged(date: JournalDate.fromJiffy(from)),
    );
    await c.animateToPage(
      fromPage,
      duration: Durations.medium1,
      curve: Curves.easeInOut,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final page = fromPage + timer.tick;
      if (page > toPage) {
        timer.cancel();
        if (mounted) _isPlaying = false;
        return;
      }
      final dayIdx = (page - 1) ~/ 2;
      final date = startOfYear.add(days: dayIdx);
      context.read<DiscoverJournalBloc>().add(
        DiscoverJournalDateChanged(date: JournalDate.fromJiffy(date)),
      );
      _isAnimating = true;
      c
          .animateToPage(
            page,
            duration: Durations.medium1,
            curve: Curves.easeInOut,
          )
          .whenComplete(() {
            if (mounted) _isAnimating = false;
          });
    });
  }
}
