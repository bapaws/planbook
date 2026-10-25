import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/discover/bookshelf/model/notebook_kind.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_flight.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_reader_scope.dart';
import 'package:flutter_planbook/discover/bookshelf/view/root_stack_router_scope.dart';
import 'package:flutter_planbook/discover/diary/bloc/diary_notebook_bloc.dart';
import 'package:flutter_planbook/discover/diary/view/diary_book_view.dart';
import 'package:flutter_planbook/discover/journal/bloc/discover_journal_bloc.dart';
import 'package:flutter_planbook/discover/journal/model/journal_date.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_page.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/discover/view/root_discover_journal_title_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:pull_down_button/pull_down_button.dart';

/// 负责一本书的飞行、翻开和合上。书架只负责把起点矩形交过来。
@RoutePage()
class NotebookReaderPage extends StatefulWidget {
  const NotebookReaderPage({required this.kind, super.key});

  final NotebookKind kind;

  @override
  State<NotebookReaderPage> createState() => NotebookReaderPageState();
}

class NotebookReaderPageState extends State<NotebookReaderPage> {
  final GlobalKey _stageKey = GlobalKey();
  NotebookLaunchRequest? _launch;
  NotebookReaderController? _reader;
  Rect? _source;
  Rect? _target;
  var _measuring = true;
  var _busy = true;
  var _closeQueued = false;
  var _popping = false;
  var _allowPop = false;
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void initState() {
    super.initState();
    _launch = NotebookLaunch.take();
    final launch = _launch;
    if (launch == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return;
    }
    _reader = NotebookReaderController()
      ..onCoverClosed = () {
        if (!_busy) closeNotebook();
      };
    WidgetsBinding.instance.addPostFrameCallback((_) => _fly());
  }

  @override
  void dispose() {
    final onClosed = _launch?.onClosed;
    if (onClosed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onClosed());
    }
    _reader?.dispose();
    super.dispose();
  }

  /// 测试里没有首页 bloc，底部按钮只在正式环境跟着飞行切换。
  void _syncOpenedNotebook(NotebookKind? kind) {
    try {
      context.read<RootDiscoverBloc>().add(RootDiscoverNotebookChanged(kind));
    } on ProviderNotFoundException {
      return;
    }
  }

  Rect? _toStage(Rect? global) {
    final stage = _stageKey.currentContext?.findRenderObject();
    if (stage is! RenderBox ||
        !stage.hasSize ||
        global == null ||
        global.isEmpty) {
      return null;
    }
    return stage.globalToLocal(global.topLeft) & global.size;
  }

  Future<void> _frame() async {
    WidgetsBinding.instance.ensureVisualUpdate();
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _fly() async {
    final reader = _reader;
    final launch = _launch;
    if (reader == null || launch == null) return;
    try {
      for (var frame = 0; frame < 8; frame++) {
        await _frame();
        if (!mounted) return;
        final target = _toStage(reader.coverRect);
        final source = _toStage(launch.sourceRect);
        if (target != null && source != null) {
          _target = target;
          _source = source;
          break;
        }
      }
      if (!mounted) return;
      setState(() => _measuring = false);
      await _frame();
      if (!mounted) return;
      final flight = _flight;
      if (flight == null) return;
      final status = await _awaitFlight(flight);
      if (!mounted || status != AnimationStatus.completed) return;
      await reader.open();
      if (!mounted) return;
      if (_closeQueued) {
        _busy = false;
        await closeNotebook();
        return;
      }
      reader.showControls(visible: true);
      setState(() => _busy = false);
    } on TickerCanceled {
      // 离开页面时停止飞行，不再推动画。
    }
  }

  NotebookFlightHost? get _flight {
    final route = _route;
    if (route is! NotebookFlightHost) return null;
    return route! as NotebookFlightHost;
  }

  Future<AnimationStatus> _awaitFlight(NotebookFlightHost route) {
    final animation = _route!.animation!;
    final completer = Completer<AnimationStatus>();
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      animation.removeStatusListener(listener);
      if (!completer.isCompleted) completer.complete(status);
    }

    animation.addStatusListener(listener);
    // 和缩小同时开始，避免底部按钮先变、封面再飞。
    _syncOpenedNotebook(widget.kind);
    route.startFlight();
    if (animation.status == AnimationStatus.completed ||
        animation.status == AnimationStatus.dismissed) {
      animation.removeStatusListener(listener);
      if (!completer.isCompleted) completer.complete(animation.status);
    }
    return completer.future;
  }

  /// 返回键、关闭按钮和封面回翻共用。飞行中再次关闭会等翻开结束后再合上。
  Future<void> closeNotebook() async {
    final reader = _reader;
    final launch = _launch;
    if (reader == null || launch == null || _popping) return;
    if (_busy) {
      _closeQueued = true;
      return;
    }
    _popping = true;
    _closeQueued = false;
    setState(() => _busy = true);
    reader.showControls(visible: false);
    try {
      await reader.close();
      if (!mounted) return;
      await _frame();
      if (!mounted) return;
      setState(() {
        _target = _toStage(reader.coverRect) ?? _target;
        _source = _toStage(launch.coverRectOf()) ?? _source;
        _allowPop = true;
      });
      await _frame();
      if (!mounted) return;
      _syncOpenedNotebook(null);
      Navigator.of(context).pop();
    } on TickerCanceled {
      // 路由卸载会取消合书动画。
    }
  }

  @override
  Widget build(BuildContext context) {
    final launch = _launch;
    final reader = _reader;
    if (launch == null || reader == null) return const SizedBox.shrink();
    final animation = _route?.animation ?? kAlwaysDismissedAnimation;
    return RootStackRouterScope(
      child: PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) closeNotebook();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) => notebookFlightScrim(
                progress: notebookFlightProgress(animation.value),
                onTap: closeNotebook,
              ),
            ),
            AppScaffold(
              backgroundColor: Colors.transparent,
              showBackground: false,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: ListenableBuilder(
                  listenable: reader,
                  builder: (context, child) => Visibility(
                    visible: reader.controlsVisible,
                    maintainSize: true,
                    maintainState: true,
                    maintainAnimation: true,
                    child: child!,
                  ),
                  child: AppBar(
                    forceMaterialTransparency: true,
                    automaticallyImplyLeading: false,
                    leading: IconButton(
                      tooltip: context.l10n.close,
                      onPressed: closeNotebook,
                      icon: const Icon(Icons.close),
                    ),
                    titleSpacing: 0,
                    title: IgnorePointer(
                      ignoring: _busy,
                      child: _title(launch),
                    ),
                    actions: _actions(launch),
                  ),
                ),
              ),
              body: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final progress = notebookFlightProgress(animation.value);
                  final target = _target;
                  final source = _source;
                  final rect = source == null || target == null
                      ? target
                      : Rect.lerp(source, target, progress);
                  final transform = Matrix4.identity();
                  if (!_measuring && target != null && rect != null) {
                    final sx = rect.width / target.width;
                    final sy = rect.height / target.height;
                    transform
                      ..translateByDouble(
                        rect.left - target.left * sx,
                        rect.top - target.top * sy,
                        0,
                        1,
                      )
                      ..scaleByDouble(sx, sy, 1, 1);
                  }
                  return Stack(
                    key: _stageKey,
                    fit: StackFit.expand,
                    children: [
                      ExcludeSemantics(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: closeNotebook,
                        ),
                      ),
                      ExcludeSemantics(
                        excluding: _busy || _measuring,
                        child: Transform(
                          key: const Key('notebook-reader-transform'),
                          transform: transform,
                          child: IgnorePointer(
                            ignoring: _busy,
                            child: Opacity(
                              opacity: _measuring ? 0 : 1,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                child: NotebookReaderScope(
                  controller: reader,
                  child:
                      launch.readerBuilder?.call(context, widget.kind) ??
                      (widget.kind == NotebookKind.diary
                          ? const DiaryBookView()
                          : const DiscoverJournalPage()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(NotebookLaunchRequest launch) {
    final l10n = context.l10n;
    if (!launch.productionChrome) {
      return Text(
        widget.kind == NotebookKind.diary ? l10n.diaryBook : l10n.planbook,
      );
    }
    if (widget.kind == NotebookKind.diary) {
      return BlocBuilder<DiaryNotebookBloc, DiaryNotebookState>(
        builder: (context, state) => RootDiscoverJournalTitleView(
          date: Jiffy.parseFromDateTime(DateTime(state.selectedYear)),
          isCalendarExpanded: state.isCalendarExpanded,
          onDateSelected: (date) => context.read<DiaryNotebookBloc>().add(
            DiaryNotebookYearChanged(date.year),
          ),
          onCalendarToggled: () => context.read<DiaryNotebookBloc>().add(
            const DiaryNotebookCalendarToggled(),
          ),
        ),
      );
    }
    return BlocBuilder<DiscoverJournalBloc, DiscoverJournalState>(
      builder: (context, state) => RootDiscoverJournalTitleView(
        date: state.date.date,
        isCalendarExpanded: state.isCalendarExpanded,
        onDateSelected: (date) => context.read<DiscoverJournalBloc>().add(
          DiscoverJournalDateChanged(date: JournalDate.fromJiffy(date)),
        ),
        onCalendarToggled: () => context.read<DiscoverJournalBloc>().add(
          const DiscoverJournalCalendarToggled(),
        ),
      ),
    );
  }

  List<Widget> _actions(NotebookLaunchRequest launch) {
    if (_busy || !launch.productionChrome) return const [];
    return [
      PullDownButton(
        itemBuilder: _menuItems,
        buttonBuilder: (context, showMenu) => CupertinoButton(
          onPressed: showMenu,
          child: const FaIcon(FontAwesomeIcons.ellipsis),
        ),
      ),
    ];
  }

  /// 封面和自动播放两本都有。编辑和导出只在日记本，放大左右页只在计划本。
  List<PullDownMenuEntry> _menuItems(BuildContext context) {
    final l10n = context.l10n;
    final diary = widget.kind == NotebookKind.diary;
    return [
      PullDownMenuItem(
        icon: FontAwesomeIcons.bookOpen.data,
        title: diary ? l10n.diaryEditNotebook : l10n.journalSetYearCover,
        onTap: () {
          if (diary) {
            final year = context.read<DiaryNotebookBloc>().state.selectedYear;
            context.router.push(DiaryNotebookSettingsRoute(year: year));
            return;
          }
          final journalState = context.read<DiscoverJournalBloc>().state;
          context.router.push(
            DiscoverJournalCoverRoute(
              year: journalState.date.year,
              currentCoverImage: journalState.coverBackgroundImage,
            ),
          );
        },
      ),
      if (diary) ...[
        PullDownMenuItem(
          icon: FontAwesomeIcons.penToSquare.data,
          title: l10n.edit,
          onTap: () {
            final reader = _reader;
            if (reader == null) return;
            unawaited(reader.edit());
          },
        ),
        PullDownMenuItem(
          icon: FontAwesomeIcons.download.data,
          title: l10n.diaryExport,
          onTap: () {
            final year = context.read<DiaryNotebookBloc>().state.selectedYear;
            context.router.push(DiaryExportRoute(year: year));
          },
        ),
      ],
      const PullDownMenuDivider.large(),
      PullDownMenuItem(
        icon: FontAwesomeIcons.play.data,
        title: l10n.autoPlay,
        onTap: () {
          context.read<RootDiscoverBloc>().add(const RootDiscoverAutoPlay());
        },
      ),
      if (!diary) ...[
        const PullDownMenuDivider.large(),
        PullDownMenuItem(
          icon: FontAwesomeIcons.magnifyingGlass.data,
          title: l10n.journalEnlargeLeftPage,
          subtitle: l10n.journalEnlargeLeftPageSubtitle,
          onTap: () {
            context.read<DiscoverJournalBloc>().add(
              const DiscoverJournalLeftEnlargedToggled(),
            );
          },
        ),
        PullDownMenuItem(
          icon: FontAwesomeIcons.magnifyingGlass.data,
          title: l10n.journalEnlargeRightPage,
          subtitle: l10n.journalEnlargeRightPageSubtitle,
          onTap: () {
            context.read<DiscoverJournalBloc>().add(
              const DiscoverJournalRightEnlargedToggled(),
            );
          },
        ),
      ],
    ];
  }
}
