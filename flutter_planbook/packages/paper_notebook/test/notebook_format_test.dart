import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_notebook/src/layout/notebook_format.dart';
import 'package:paper_notebook/src/paper_notebook_style.dart';

void main() {
  const format = NotebookFormat.defaults;

  test('right page is A4 at 2px/mm', () {
    expect(format.pageWidth, 420);
    expect(format.pageHeight, 594);
    expect(format.aspect, closeTo(210 / 297, 0.0001));
    expect(
      format.pageWidth / format.pageHeight,
      closeTo(format.aspect, 0.0001),
    );
  });

  test('left page is A4 and fully visible in the viewport', () {
    expect(format.leftLeafWidth, format.pageWidth);
    expect(format.leftVisibleFraction, 1.0);
    expect(format.leftVisibleWidth, format.pageWidth);
    expect(format.viewCropLeft, 0);
    expect(format.viewWidth, format.designWidth);
  });

  test('leather peeks on all four sides of the paper', () {
    expect(format.leatherPeek, format.leatherRadius - format.pageOuterRadius);
    expect(format.leatherPeekTop, format.leatherPeek);
    expect(format.leatherPeekBottom, format.leatherPeek);
    expect(format.leatherPeekLeft, format.leatherPeek);
    expect(format.leatherPeekRight, format.leatherPeek);
    expect(format.leatherRadius, 32);
    expect(format.pageOuterRadius, 22);
    expect(format.leatherPeek, 10);
    expect(format.pageTop, format.leatherInsets.top + format.leatherPeekTop);
    expect(
      format.pageLeft,
      format.leatherInsets.left + format.leatherPeekLeft + format.leftLeafWidth,
    );
    expect(format.frontCoverLeft, format.pageLeft);
    expect(format.frontCoverTop, format.leatherInsets.top);
    expect(format.frontCoverWidth, format.pageWidth + format.leatherPeekRight);
    expect(
      format.frontCoverHeight,
      format.leatherPeekTop + format.pageHeight + format.leatherPeekBottom,
    );
    expect(
      format.designHeight,
      format.leatherInsets.top +
          format.leatherPeekTop +
          format.pageHeight +
          format.leatherPeekBottom +
          format.leatherInsets.bottom,
    );
    expect(
      format.designWidth,
      format.leatherInsets.left +
          format.leatherPeekLeft +
          format.leftLeafWidth +
          format.pageWidth +
          format.leatherPeekRight +
          format.leatherInsets.right,
    );
  });

  test('fitScale letterboxes a tall phone to the full spread', () {
    expect(
      format.fitScale(const Size(390, 800)),
      closeTo(390 / format.viewWidth, 0.0001),
    );
  });

  test('fitRightPageScale fills the right leaf on a tall phone', () {
    expect(
      format.filledViewLeft,
      closeTo(
        format.pageLeft - format.leftLeafWidth * format.leftPageReveal,
        0.001,
      ),
    );
    expect(format.filledViewRight, closeTo(format.designWidth - 8, 0.001));
    expect(
      format.fitRightPageScale(const Size(390, 800)),
      closeTo(390 / format.filledViewWidth, 0.0001),
    );
    expect(
      format.filledViewWidth,
      format.filledViewRight - format.filledViewLeft,
    );
  });

  test('fitScale pillarboxes a short wide screen to height', () {
    expect(
      format.fitScale(const Size(900, 500)),
      closeTo(500 / format.designHeight, 0.0001),
    );
  });

  test('A5 keeps concentric corners and a smaller page', () {
    final a5 = NotebookFormat(PaperNotebookStyle.a5());
    expect(a5.pageWidth, 148 * 2);
    expect(a5.pageHeight, 210 * 2);
    expect(a5.leatherPeek, a5.leatherRadius - a5.pageOuterRadius);
    expect(a5.leatherPeek, 16);
    expect(a5.aspect, closeTo(148 / 210, 0.0001));
  });
}
