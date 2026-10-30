import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:paper_notebook/src/paper_notebook_style.dart';

/// 由 [PaperNotebookStyle] 算出的双页画布几何。
class NotebookFormat {
  const NotebookFormat(this.style);

  static const defaults = NotebookFormat(PaperNotebookStyle.defaults);

  final PaperNotebookStyle style;

  double get mmWidth => style.pageSize.mmWidth;
  double get mmHeight => style.pageSize.mmHeight;
  double get pxPerMm => style.pxPerMm;

  double get pageWidth => mmWidth * pxPerMm;
  double get pageHeight => mmHeight * pxPerMm;
  Size get pageSize => Size(pageWidth, pageHeight);

  EdgeInsets get leatherInsets => style.leatherInsets;
  double get leatherRadius => style.leatherRadius;
  double get pageOuterRadius => style.pageOuterRadius;
  double get spineRadius => style.spineRadius;
  double get leatherPeek => style.leatherPeek;

  double get leatherPeekTop => leatherPeek;
  double get leatherPeekBottom => leatherPeek;
  double get leatherPeekLeft => leatherPeek;
  double get leatherPeekRight => leatherPeek;

  double get leftLeafWidth => pageWidth;
  double get leftVisibleFraction => 1;
  double get leftVisibleWidth => pageWidth * leftVisibleFraction;
  double get viewCropLeft => 0;

  double get designWidth =>
      leatherInsets.left +
      leatherPeekLeft +
      leftLeafWidth +
      pageWidth +
      leatherPeekRight +
      leatherInsets.right;

  double get designHeight =>
      leatherInsets.top +
      leatherPeekTop +
      pageHeight +
      leatherPeekBottom +
      leatherInsets.bottom;

  Size get size => Size(designWidth, designHeight);

  double get viewWidth => designWidth - viewCropLeft;

  double get leftPageReveal => style.leftPageReveal;
  double get filledRightInset => style.filledRightInset;

  double get filledViewLeft => pageLeft - leftLeafWidth * leftPageReveal;

  double get filledViewRight =>
      designWidth - (leatherInsets.right - filledRightInset);

  double get filledViewWidth => filledViewRight - filledViewLeft;

  double get filledViewShiftX =>
      (designWidth - filledViewLeft - filledViewRight) / 2;

  double get aspect => mmWidth / mmHeight;
  double get viewAspect => viewWidth / designHeight;

  double get pageLeft => leatherInsets.left + leatherPeekLeft + leftLeafWidth;

  double get pageTop => leatherInsets.top + leatherPeekTop;

  double get frontCoverLeft => pageLeft;
  double get frontCoverTop => leatherInsets.top;
  double get frontCoverWidth => pageWidth + leatherPeekRight;
  double get frontCoverHeight =>
      leatherPeekTop + pageHeight + leatherPeekBottom;

  double get backCoverLeft => leatherInsets.left;

  double fitScale(Size available) {
    if (available.width < 1 || available.height < 1) return 1;
    return math.min(
      available.width / viewWidth,
      available.height / designHeight,
    );
  }

  double fitRightPageScale(Size available) {
    if (available.width < 1 || available.height < 1) return 1;
    return math.min(
      available.width / filledViewWidth,
      available.height / designHeight,
    );
  }

  static const shiftDoneFraction = 0.75;

  double openShiftX(double t, [double zoom = 0]) {
    final u = (t / shiftDoneFraction).clamp(0.0, 1.0);
    final coverShift = -pageLeft * (1 - u) / 2;
    return coverShift + filledViewShiftX * zoom;
  }

  @override
  bool operator ==(Object other) {
    return other is NotebookFormat && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
