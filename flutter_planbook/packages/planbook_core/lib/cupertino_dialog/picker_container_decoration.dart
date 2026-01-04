// Copyright (c) 2024 Philip Softworks. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

const int calendarBluredLightBackgroundColorAlpha = 180;
const int calendarBluredDarkBackgroundColorAlpha = 160;

/// A enum for the picker's background appearance.
enum PickerBackgroundType {
  /// The provided color will be applied only.
  plainColor,

  /// The transparency to the provided color will be applied
  /// using a background blur.
  transparentAndBlured,
}

const List<BoxShadow> pickerBoxShadow = <BoxShadow>[
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.145),
    blurRadius: 85,
    spreadRadius: 9,
  ),
];
final BorderRadius pickerBorderRadius = BorderRadius.circular(13);
final CupertinoDynamicColor pickerBackgroundColor =
    CupertinoDynamicColor.withBrightness(
      color: CupertinoColors.systemBackground,
      darkColor: CupertinoColors.tertiarySystemBackground.darkColor,
    );
const PickerBackgroundType pickerBackgroundType =
    PickerBackgroundType.transparentAndBlured;

/// A decoration class for the picker's background container.
class PickerContainerDecoration {
  /// Creates a picker's container decoration class with default values
  /// for non-provided parameters.
  factory PickerContainerDecoration({
    BorderRadius? borderRadius,
    Color? backgroundColor,
    PickerBackgroundType backgroundType = pickerBackgroundType,
    List<BoxShadow>? boxShadow,
  }) {
    var color = backgroundColor ?? pickerBackgroundColor;

    if (backgroundType == PickerBackgroundType.transparentAndBlured) {
      color = color.alpha > calendarBluredLightBackgroundColorAlpha
          ? color.withAlpha(calendarBluredLightBackgroundColorAlpha)
          : color;
    }

    return PickerContainerDecoration._(
      borderRadius: borderRadius ?? pickerBorderRadius,
      backgroundColor: color,
      backgroundType: backgroundType,
      boxShadow: boxShadow ?? pickerBoxShadow,
    );
  }

  const PickerContainerDecoration._({
    required this.borderRadius,
    required this.backgroundColor,
    required this.backgroundType,
    required this.boxShadow,
  });

  /// Creates a picker's container decoration class with default values
  /// for non-provided parameters.
  ///
  /// Applies the [CupertinoDynamicColor.resolve] method for colors.
  factory PickerContainerDecoration.withDynamicColor(
    BuildContext context, {
    BorderRadius? borderRadius,
    CupertinoDynamicColor? backgroundColor,
    PickerBackgroundType backgroundType = pickerBackgroundType,
    List<BoxShadow>? boxShadow,
  }) {
    var color = backgroundColor ?? pickerBackgroundColor;

    if (backgroundType == PickerBackgroundType.transparentAndBlured) {
      color = CupertinoDynamicColor.withBrightness(
        color: color.withAlpha(calendarBluredLightBackgroundColorAlpha),
        darkColor: color.darkColor.withAlpha(
          calendarBluredDarkBackgroundColorAlpha,
        ),
      );
    }

    return PickerContainerDecoration(
      backgroundColor: CupertinoDynamicColor.resolve(color, context),
      backgroundType: backgroundType,
      boxShadow: boxShadow,
      borderRadius: borderRadius ?? pickerBorderRadius,
    );
  }

  /// The [borderRadius] of the calendar container.
  final BorderRadius borderRadius;

  /// The [backgroundColor] of the calendar container.
  final Color backgroundColor;

  /// The [PickerBackgroundType] of the calendar container.
  final PickerBackgroundType backgroundType;

  /// The [boxShadow] of the calendar container.
  final List<BoxShadow> boxShadow;

  /// Creates a copy of the class with the provided parameters.
  PickerContainerDecoration copyWith({
    BorderRadius? borderRadius,
    Color? backgroundColor,
    List<BoxShadow>? boxShadow,
  }) {
    return PickerContainerDecoration(
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      boxShadow: boxShadow ?? this.boxShadow,
    );
  }
}
