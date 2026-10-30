import 'package:flutter/painting.dart';

/// ISO 纸张毫米尺寸。逻辑像素 = mm × [PaperNotebookStyle.pxPerMm]。
class PaperPageSize {
  const PaperPageSize({required this.mmWidth, required this.mmHeight});

  static const a4 = PaperPageSize(mmWidth: 210, mmHeight: 297);
  static const a5 = PaperPageSize(mmWidth: 148, mmHeight: 210);

  final double mmWidth;
  final double mmHeight;

  @override
  bool operator ==(Object other) {
    return other is PaperPageSize &&
        other.mmWidth == mmWidth &&
        other.mmHeight == mmHeight;
  }

  @override
  int get hashCode => Object.hash(mmWidth, mmHeight);
}

/// 本子几何与动画时长。内页外角与牛皮纸外角同圆心：peek = leatherRadius − pageOuterRadius。
class PaperNotebookStyle {
  const PaperNotebookStyle({
    this.pageSize = PaperPageSize.a4,
    this.pxPerMm = 2,
    this.leatherRadius = 32,
    this.pageOuterRadius = 22,
    this.spineRadius = 12,
    this.leatherInsets = const EdgeInsets.fromLTRB(16, 12, 16, 16),
    this.leftPageReveal = 1 / 10,
    this.filledRightInset = 8,
    this.fillOpenedView = true,
    this.coverOpen = const Duration(milliseconds: 900),
    this.coverClose = const Duration(milliseconds: 560),
    this.pageFill = const Duration(milliseconds: 400),
    this.pageTurn = const Duration(milliseconds: 560),
    this.pageSettle = const Duration(milliseconds: 480),
  });

  factory PaperNotebookStyle.a5({
    double leatherRadius = 32,
    double pageOuterRadius = 16,
    double spineRadius = 3,
    EdgeInsets leatherInsets = const EdgeInsets.fromLTRB(16, 12, 16, 16),
    double leftPageReveal = 1 / 10,
    double filledRightInset = 8,
    bool fillOpenedView = true,
  }) {
    return PaperNotebookStyle(
      pageSize: PaperPageSize.a5,
      leatherRadius: leatherRadius,
      pageOuterRadius: pageOuterRadius,
      spineRadius: spineRadius,
      leatherInsets: leatherInsets,
      leftPageReveal: leftPageReveal,
      filledRightInset: filledRightInset,
      fillOpenedView: fillOpenedView,
    );
  }

  static const defaults = PaperNotebookStyle();

  final PaperPageSize pageSize;
  final double pxPerMm;
  final double leatherRadius;
  final double pageOuterRadius;
  final double spineRadius;
  final EdgeInsets leatherInsets;
  final double leftPageReveal;
  final double filledRightInset;
  final bool fillOpenedView;
  final Duration coverOpen;
  final Duration coverClose;
  final Duration pageFill;
  final Duration pageTurn;
  final Duration pageSettle;

  double get leatherPeek => leatherRadius - pageOuterRadius;

  @override
  bool operator ==(Object other) {
    return other is PaperNotebookStyle &&
        other.pageSize.mmWidth == pageSize.mmWidth &&
        other.pageSize.mmHeight == pageSize.mmHeight &&
        other.pxPerMm == pxPerMm &&
        other.leatherRadius == leatherRadius &&
        other.pageOuterRadius == pageOuterRadius &&
        other.spineRadius == spineRadius &&
        other.leatherInsets == leatherInsets &&
        other.leftPageReveal == leftPageReveal &&
        other.filledRightInset == filledRightInset &&
        other.fillOpenedView == fillOpenedView &&
        other.coverOpen == coverOpen &&
        other.coverClose == coverClose &&
        other.pageFill == pageFill &&
        other.pageTurn == pageTurn &&
        other.pageSettle == pageSettle;
  }

  @override
  int get hashCode => Object.hash(
    pageSize.mmWidth,
    pageSize.mmHeight,
    pxPerMm,
    leatherRadius,
    pageOuterRadius,
    spineRadius,
    leatherInsets,
    leftPageReveal,
    filledRightInset,
    fillOpenedView,
    coverOpen,
    coverClose,
    pageFill,
    pageTurn,
    pageSettle,
  );
}
