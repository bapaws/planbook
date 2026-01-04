// Copyright (c) 2024 Philip Softworks. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

// ANIMATION

const Duration calendarAnimationDuration = Duration(milliseconds: 430);
const Duration calendarAnimationReverseDuration = Duration(milliseconds: 280);
const Duration monthScrollDuration = Duration(milliseconds: 400);
const Cubic calendarAnimationCurve = Curves.ease;
const Duration innerPickersFadeDuration = Duration(milliseconds: 250);

abstract final class CalendarAnimations {
  static TweenSequence<double> heightAnimation({
    required double height,
  }) {
    return TweenSequence<double>(
      generateHeightAnimation(
        height: height,
        percentageList: _heightPercentages,
      ).toList(),
    );
  }

  static final List<double> _heightPercentages = <double>[
    22.590361445783135,
    33.13253012048193,
    45.18072289156627,
    55.72289156626506,
    66.26506024096386,
    73.79518072289156,
    79.81927710843374,
    85.2409638554217,
    88.85542168674698,
    91.86746987951807,
    93.37349397590361,
    94.87951807228916,
    96.3855421686747,
    97.89156626506023,
    98.79518072289156,
    100,
    maxHeightPercentage,
    100,
  ];

  static const double maxHeightPercentage = 100.90361445783131;

  static Iterable<TweenSequenceItem<double>> generateHeightAnimation({
    required double height,
    required List<double> percentageList,
  }) sync* {
    var begin = 0.0;

    for (final percentage in percentageList) {
      final end = percentage * height / 100;
      yield TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: begin,
          end: end,
        ),
        weight: 1,
      );
      begin = end;
    }
  }

  static TweenSequence<double> scaleAnimation({
    required double maxScale,
  }) {
    return TweenSequence<double>(
      generateScaleAnimation(
        maxScale: maxScale,
        valueList: _scaleValues,
      ).toList(),
    );
  }

  /// Considering that [maxScale] is [1.0]
  static final List<double> _scaleValues = <double>[
    0.39,
    0.5,
    0.61,
    0.7,
    0.785,
    0.85,
    0.9,
    0.94,
    0.965,
    0.985,
    0.997,
    1,
    1.01,
    1,
  ];

  static Iterable<TweenSequenceItem<double>> generateScaleAnimation({
    required double maxScale,
    required List<double> valueList,
  }) sync* {
    var begin = 0.0;

    for (final value in valueList) {
      final end = value * maxScale;
      yield TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: begin,
          end: end,
        ),
        weight: 1,
      );
      begin = end;
    }
  }
}
