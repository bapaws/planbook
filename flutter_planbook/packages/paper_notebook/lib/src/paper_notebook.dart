import 'package:flutter/material.dart';
import 'package:paper_notebook/src/engine/notebook_shell.dart';
import 'package:paper_notebook/src/engine/paper_page_turn.dart';
import 'package:paper_notebook/src/layout/notebook_format.dart';
import 'package:paper_notebook/src/paper_notebook_cover.dart';
import 'package:paper_notebook/src/paper_notebook_pattern.dart';
import 'package:paper_notebook/src/paper_notebook_scope.dart';
import 'package:paper_notebook/src/paper_notebook_style.dart';
import 'package:paper_notebook/src/paper_notebook_theme.dart';

typedef PaperNotebookPageBuilder =
    Widget Function(BuildContext context, int index);

typedef PaperNotebookCoverBuilder = Widget Function(BuildContext context);

/// 开合封面与翻页。由 [PaperNotebook] 在挂载时绑定。
class PaperNotebookController extends ChangeNotifier {
  _PaperNotebookState? _state;
  var _coverClosed = true;
  var _index = 0;
  var _animating = false;
  var _ritualSession = 0;

  void _attach(_PaperNotebookState state) {
    _state = state;
    _coverClosed = state._coverClosed;
    _index = state._index;
  }

  void _detach(_PaperNotebookState state) {
    if (identical(_state, state)) _state = null;
  }

  void _sync({required bool coverClosed, required int index, bool? animating}) {
    final nextAnimating = animating ?? _animating;
    if (_coverClosed == coverClosed &&
        _index == index &&
        _animating == nextAnimating) {
      return;
    }
    _coverClosed = coverClosed;
    _index = index;
    _animating = nextAnimating;
    notifyListeners();
  }

  Future<void> openCover() {
    return _state?._openCover() ?? Future.value();
  }

  Future<void> closeCover() {
    return _state?._closeCover() ?? Future.value();
  }

  Future<void> toggleCover() {
    if (isCoverClosed) return openCover();
    return closeCover();
  }

  /// 合上停顿后再打开。
  Future<void> playOpenRitual({
    Duration dwell = const Duration(milliseconds: 600),
  }) {
    return _state?._playOpenRitual(dwell) ?? Future.value();
  }

  /// 取消尚未打开的仪式（例如离开 Tab）。
  void cancelOpenRitual() {
    _ritualSession++;
    _state?._ritual = false;
  }

  Future<void> nextPage() {
    return _state?._nextPage() ?? Future.value();
  }

  Future<void> previousPage() {
    return _state?._previousPage() ?? Future.value();
  }

  /// 打开封面（若合上）。然后播一次折页到目标页，中间页不逐张翻过。
  Future<void> animateTo(int index) {
    return _state?._animateTo(index) ?? Future.value();
  }

  /// 不播动画直接落到目标页。封面还合着时用这个，翻页动画反正也看不见。
  void jumpTo(int index) => _state?._jumpTo(index);

  bool get isCoverClosed => _state?._coverClosed ?? _coverClosed;

  bool get isAnimating {
    final state = _state;
    if (state == null) return _animating;
    return state._isAnimating;
  }

  int get index => _state?._index ?? _index;
}

/// 牛皮纸本子：封面开合 + 内页折页。
class PaperNotebook extends StatefulWidget {
  const PaperNotebook({
    required this.pageBuilder,
    this.controller,
    this.initialIndex = 0,
    this.pageCount,
    this.coverBuilder,
    this.coverClosed = true,
    this.gesturesEnabled = true,
    this.coverGesturesEnabled = true,
    this.closesCoverOnBack,
    this.closesCoverOnForward,
    this.paperPattern,
    this.style,
    this.theme,
    this.onIndexChanged,
    this.onCoverOpened,
    this.onCoverClosed,
    super.key,
  });

  final PaperNotebookPageBuilder pageBuilder;
  final PaperNotebookController? controller;
  final int initialIndex;

  /// `null` 表示不限页数。
  final int? pageCount;
  final PaperNotebookCoverBuilder? coverBuilder;
  final bool coverClosed;
  final bool gesturesEnabled;
  final bool coverGesturesEnabled;

  /// `null`：第一页再往回翻则合上封面。
  final bool? closesCoverOnBack;

  /// `null`：最后一页再往前翻则合上封面（需设置 [pageCount]）。
  final bool? closesCoverOnForward;
  final PaperNotebookPattern? paperPattern;
  final PaperNotebookStyle? style;
  final PaperNotebookTheme? theme;
  final ValueChanged<int>? onIndexChanged;
  final VoidCallback? onCoverOpened;
  final VoidCallback? onCoverClosed;

  static const canvasKey = NotebookShell.canvasKey;
  static const viewportKey = NotebookShell.viewportKey;
  static const frontCoverKey = NotebookShell.frontCoverKey;
  static const coverInsideKey = NotebookShell.coverInsideKey;
  static const openShiftKey = NotebookShell.openShiftKey;
  static const coverBackgroundKey = NotebookShell.coverBackgroundKey;

  @override
  State<PaperNotebook> createState() => _PaperNotebookState();
}

class _PaperNotebookState extends State<PaperNotebook> {
  final _cover = CoverTurnController();
  final _turn = PaperPageTurnController();
  late PaperNotebookController _controller;
  var _ownsController = false;
  late int _index;
  late bool _coverClosed;
  var _ritual = false;
  int? _skipTo;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _coverClosed = widget.coverClosed;
    final incoming = widget.controller;
    if (incoming != null) {
      _controller = incoming;
    } else {
      _controller = PaperNotebookController();
      _ownsController = true;
    }
    _controller._attach(this);
  }

  @override
  void didUpdateWidget(covariant PaperNotebook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller._detach(this);
      if (_ownsController) _controller.dispose();
      final incoming = widget.controller;
      if (incoming != null) {
        _controller = incoming;
        _ownsController = false;
      } else {
        _controller = PaperNotebookController();
        _ownsController = true;
      }
      _controller._attach(this);
    }
  }

  @override
  void dispose() {
    _controller._detach(this);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  bool get _isAnimating =>
      _ritual || _skipTo != null || _cover.isAnimating || _turn.isAnimating;

  void _notify({bool? animating}) {
    _controller._sync(
      coverClosed: _coverClosed,
      index: _index,
      animating: animating ?? _isAnimating,
    );
  }

  int _clampIndex(int index) {
    final count = widget.pageCount;
    if (count == null) return index;
    if (count <= 0) return 0;
    return index.clamp(0, count - 1);
  }

  bool get _atFirstPage => _index <= 0;

  bool get _atLastPage {
    final count = widget.pageCount;
    if (count == null) return false;
    return count > 0 && _index >= count - 1;
  }

  bool get _closesCoverOnBack => widget.closesCoverOnBack ?? _atFirstPage;

  bool get _closesCoverOnForward => widget.closesCoverOnForward ?? _atLastPage;

  bool _canGoForward() {
    final count = widget.pageCount;
    if (count == null) return true;
    return _index + 1 < count;
  }

  bool _canGoBack() => _index > 0;

  int? get _peekForwardIndex {
    if (_skipTo != null && _skipTo! > _index) return _skipTo;
    if (_canGoForward()) return _index + 1;
    return null;
  }

  int? get _peekBackIndex {
    if (_skipTo != null && _skipTo! < _index) return _skipTo;
    if (_closesCoverOnBack || !_canGoBack()) return null;
    return _index - 1;
  }

  Future<void> _openCover() async {
    if (!_coverClosed) return;
    _notify(animating: true);
    await _cover.open();
  }

  Future<void> _closeCover() async {
    if (_coverClosed) return;
    _notify(animating: true);
    await _cover.close();
  }

  Future<void> _playOpenRitual(Duration dwell) async {
    final session = ++_controller._ritualSession;
    _ritual = true;
    _index = widget.initialIndex;
    _skipTo = null;
    setState(() => _coverClosed = true);
    _notify(animating: true);
    await Future<void>.delayed(dwell);
    if (!mounted || session != _controller._ritualSession) return;
    await _cover.open();
    if (!mounted || session != _controller._ritualSession) return;
    _ritual = false;
    _notify(animating: false);
  }

  Future<void> _nextPage() async {
    if (_coverClosed) {
      await _openCover();
      return;
    }
    if (_closesCoverOnForward) {
      await _closeCover();
      return;
    }
    if (!mounted || !_canGoForward()) return;
    _notify(animating: true);
    await _turn.playForward();
  }

  Future<void> _previousPage() async {
    if (_coverClosed) return;
    if (_closesCoverOnBack) {
      await _closeCover();
      return;
    }
    if (!_canGoBack()) return;
    _notify(animating: true);
    await _turn.playBack();
  }

  void _jumpTo(int index) {
    final target = _clampIndex(index);
    if (target == _index && _skipTo == null) return;
    setState(() {
      _index = target;
      _skipTo = null;
    });
    widget.onIndexChanged?.call(_index);
    _notify();
  }

  Future<void> _animateTo(int index) async {
    final target = _clampIndex(index);
    if (_coverClosed) await _openCover();
    if (!mounted) return;
    if (target == _index) return;
    _notify(animating: true);
    setState(() => _skipTo = target);
    // 目标页第一次构建可能很重（建 bloc、读数据）。等它稳定两帧再起动画，
    // 否则那一帧的耗时会被算进动画时长，翻页看起来就直接跳过去了。
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (target > _index) {
      await _turn.playForward();
    } else {
      await _turn.playBack();
    }
    if (!mounted) return;
    if (_skipTo == target) {
      setState(() {
        _index = target;
        _skipTo = null;
      });
      widget.onIndexChanged?.call(_index);
    }
    _notify(animating: false);
  }

  void _onCoverOpened() {
    if (!mounted) return;
    setState(() {
      _coverClosed = false;
      _ritual = false;
    });
    _notify(animating: false);
    widget.onCoverOpened?.call();
  }

  void _onCoverClosed() {
    if (!mounted) return;
    setState(() => _coverClosed = true);
    _notify(animating: false);
    widget.onCoverClosed?.call();
  }

  void _onForward() {
    final target = _skipTo ?? _clampIndex(_index + 1);
    _skipTo = null;
    setState(() => _index = target);
    widget.onIndexChanged?.call(_index);
    _notify();
  }

  void _onBack() {
    final target = _skipTo ?? _clampIndex(_index - 1);
    _skipTo = null;
    setState(() => _index = target);
    widget.onIndexChanged?.call(_index);
    _notify();
  }

  Widget _page(BuildContext context, int index) {
    return KeyedSubtree(
      key: ValueKey<int>(index),
      child: widget.pageBuilder(context, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? PaperNotebookStyle.defaults;
    final theme = widget.theme ?? PaperNotebookTheme.defaults;
    final pattern = widget.paperPattern ?? PaperNotebookPattern.dots;
    return PaperNotebookScope(
      format: NotebookFormat(style),
      theme: theme,
      pattern: pattern,
      child: NotebookShell(
        coverBuilder: (context) =>
            widget.coverBuilder?.call(context) ?? const PaperNotebookCover(),
        coverClosed: _coverClosed,
        coverGesturesEnabled:
            widget.coverGesturesEnabled && !_ritual && _coverClosed,
        controller: _cover,
        onCoverOpened: _onCoverOpened,
        onCoverClosed: _onCoverClosed,
        child: PaperPageTurn(
          controller: _turn,
          gesturesEnabled:
              widget.gesturesEnabled &&
              !_coverClosed &&
              !_ritual &&
              _skipTo == null,
          closesCoverOnBack: _closesCoverOnBack,
          closesCoverOnForward: _closesCoverOnForward,
          onCloseCover: _closeCover,
          onAnimationChanged: _notify,
          current: _page(context, _index),
          next: _peekForwardIndex != null
              ? _page(context, _peekForwardIndex!)
              : const SizedBox.expand(),
          previous: _peekBackIndex != null
              ? _page(context, _peekBackIndex!)
              : const SizedBox.expand(),
          onForward: _onForward,
          onBack: _onBack,
        ),
      ),
    );
  }
}
