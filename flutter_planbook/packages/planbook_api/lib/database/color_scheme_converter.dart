import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' as material;

class ColorScheme extends Equatable {
  const ColorScheme({
    required this.argb,
    required this.primaryArgb,
    required this.onPrimaryArgb,
    required this.primaryContainerArgb,
    required this.onPrimaryContainerArgb,
    required this.primaryFixedArgb,
    required this.primaryFixedDimArgb,
    required this.onPrimaryFixedArgb,
    required this.onPrimaryFixedVariantArgb,
    required this.secondaryArgb,
    required this.onSecondaryArgb,
    required this.secondaryContainerArgb,
    required this.onSecondaryContainerArgb,
    required this.secondaryFixedArgb,
    required this.secondaryFixedDimArgb,
    required this.onSecondaryFixedArgb,
    required this.onSecondaryFixedVariantArgb,
    required this.tertiaryArgb,
    required this.onTertiaryArgb,
    required this.tertiaryContainerArgb,
    required this.onTertiaryContainerArgb,
    required this.tertiaryFixedArgb,
    required this.tertiaryFixedDimArgb,
    required this.onTertiaryFixedArgb,
    required this.onTertiaryFixedVariantArgb,
    required this.errorArgb,
    required this.onErrorArgb,
    required this.errorContainerArgb,
    required this.onErrorContainerArgb,
    required this.outlineArgb,
    required this.outlineVariantArgb,
    required this.surfaceArgb,
    required this.onSurfaceArgb,
    required this.surfaceDimArgb,
    required this.surfaceBrightArgb,
    required this.surfaceContainerLowestArgb,
    required this.surfaceContainerLowArgb,
    required this.surfaceContainerArgb,
    required this.surfaceContainerHighArgb,
    required this.surfaceContainerHighestArgb,
    required this.onSurfaceVariantArgb,
    required this.inverseSurfaceArgb,
    required this.onInverseSurfaceArgb,
    required this.inversePrimaryArgb,
    required this.shadowArgb,
    required this.scrimArgb,
    required this.surfaceTintArgb,
    required this.surfaceVariantArgb,
  });

  factory ColorScheme.fromMap(Map<String, dynamic> map) {
    return ColorScheme(
      argb: map['argb'] as int,
      primaryArgb: map['primaryArgb'] as int,
      onPrimaryArgb: map['onPrimaryArgb'] as int,
      primaryContainerArgb: map['primaryContainerArgb'] as int,
      onPrimaryContainerArgb: map['onPrimaryContainerArgb'] as int,
      primaryFixedArgb: map['primaryFixedArgb'] as int,
      primaryFixedDimArgb: map['primaryFixedDimArgb'] as int,
      onPrimaryFixedArgb: map['onPrimaryFixedArgb'] as int,
      onPrimaryFixedVariantArgb: map['onPrimaryFixedVariantArgb'] as int,
      secondaryArgb: map['secondaryArgb'] as int,
      onSecondaryArgb: map['onSecondaryArgb'] as int,
      secondaryContainerArgb: map['secondaryContainerArgb'] as int,
      onSecondaryContainerArgb: map['onSecondaryContainerArgb'] as int,
      secondaryFixedArgb: map['secondaryFixedArgb'] as int,
      secondaryFixedDimArgb: map['secondaryFixedDimArgb'] as int,
      onSecondaryFixedArgb: map['onSecondaryFixedArgb'] as int,
      onSecondaryFixedVariantArgb: map['onSecondaryFixedVariantArgb'] as int,
      tertiaryArgb: map['tertiaryArgb'] as int,
      onTertiaryArgb: map['onTertiaryArgb'] as int,
      tertiaryContainerArgb: map['tertiaryContainerArgb'] as int,
      onTertiaryContainerArgb: map['onTertiaryContainerArgb'] as int,
      tertiaryFixedArgb: map['tertiaryFixedArgb'] as int,
      tertiaryFixedDimArgb: map['tertiaryFixedDimArgb'] as int,
      onTertiaryFixedArgb: map['onTertiaryFixedArgb'] as int,
      onTertiaryFixedVariantArgb: map['onTertiaryFixedVariantArgb'] as int,
      errorArgb: map['errorArgb'] as int,
      onErrorArgb: map['onErrorArgb'] as int,
      errorContainerArgb: map['errorContainerArgb'] as int,
      onErrorContainerArgb: map['onErrorContainerArgb'] as int,
      outlineArgb: map['outlineArgb'] as int,
      outlineVariantArgb: map['outlineVariantArgb'] as int,
      surfaceArgb: map['surfaceArgb'] as int,
      onSurfaceArgb: map['onSurfaceArgb'] as int,
      surfaceDimArgb: map['surfaceDimArgb'] as int,
      surfaceBrightArgb: map['surfaceBrightArgb'] as int,
      surfaceContainerLowestArgb: map['surfaceContainerLowestArgb'] as int,
      surfaceContainerLowArgb: map['surfaceContainerLowArgb'] as int,
      surfaceContainerArgb: map['surfaceContainerArgb'] as int,
      surfaceContainerHighArgb: map['surfaceContainerHighArgb'] as int,
      surfaceContainerHighestArgb: map['surfaceContainerHighestArgb'] as int,
      onSurfaceVariantArgb: map['onSurfaceVariantArgb'] as int,
      inverseSurfaceArgb: map['inverseSurfaceArgb'] as int,
      onInverseSurfaceArgb: map['onInverseSurfaceArgb'] as int,
      inversePrimaryArgb: map['inversePrimaryArgb'] as int,
      shadowArgb: map['shadowArgb'] as int,
      scrimArgb: map['scrimArgb'] as int,
      surfaceTintArgb: map['surfaceTintArgb'] as int,
      surfaceVariantArgb: map['surfaceVariantArgb'] as int,
    );
  }

  factory ColorScheme.fromJson(String source) =>
      ColorScheme.fromMap(json.decode(source) as Map<String, dynamic>);

  factory ColorScheme.fromColorScheme(
    material.ColorScheme colorScheme, {
    int? argb,
  }) {
    return ColorScheme(
      argb: argb ?? colorScheme.primary.toARGB32(),
      primaryArgb: colorScheme.primary.toARGB32(),
      onPrimaryArgb: colorScheme.onPrimary.toARGB32(),
      primaryContainerArgb: colorScheme.primaryContainer.toARGB32(),
      onPrimaryContainerArgb: colorScheme.onPrimaryContainer.toARGB32(),
      primaryFixedArgb: colorScheme.primaryFixed.toARGB32(),
      primaryFixedDimArgb: colorScheme.primaryFixedDim.toARGB32(),
      onPrimaryFixedArgb: colorScheme.onPrimaryFixed.toARGB32(),
      onPrimaryFixedVariantArgb: colorScheme.onPrimaryFixedVariant.toARGB32(),
      secondaryArgb: colorScheme.secondary.toARGB32(),
      onSecondaryArgb: colorScheme.onSecondary.toARGB32(),
      secondaryContainerArgb: colorScheme.secondaryContainer.toARGB32(),
      onSecondaryContainerArgb: colorScheme.onSecondaryContainer.toARGB32(),
      secondaryFixedArgb: colorScheme.secondaryFixed.toARGB32(),
      secondaryFixedDimArgb: colorScheme.secondaryFixedDim.toARGB32(),
      onSecondaryFixedArgb: colorScheme.onSecondaryFixed.toARGB32(),
      onSecondaryFixedVariantArgb: colorScheme.onSecondaryFixedVariant
          .toARGB32(),
      tertiaryArgb: colorScheme.tertiary.toARGB32(),
      onTertiaryArgb: colorScheme.onTertiary.toARGB32(),
      tertiaryContainerArgb: colorScheme.tertiaryContainer.toARGB32(),
      onTertiaryContainerArgb: colorScheme.onTertiaryContainer.toARGB32(),
      tertiaryFixedArgb: colorScheme.tertiaryFixed.toARGB32(),
      tertiaryFixedDimArgb: colorScheme.tertiaryFixedDim.toARGB32(),
      onTertiaryFixedArgb: colorScheme.onTertiaryFixed.toARGB32(),
      onTertiaryFixedVariantArgb: colorScheme.onTertiaryFixedVariant.toARGB32(),
      errorArgb: colorScheme.error.toARGB32(),
      onErrorArgb: colorScheme.onError.toARGB32(),
      errorContainerArgb: colorScheme.errorContainer.toARGB32(),
      onErrorContainerArgb: colorScheme.onErrorContainer.toARGB32(),
      outlineArgb: colorScheme.outline.toARGB32(),
      outlineVariantArgb: colorScheme.outlineVariant.toARGB32(),
      surfaceArgb: colorScheme.surface.toARGB32(),
      onSurfaceArgb: colorScheme.onSurface.toARGB32(),
      surfaceDimArgb: colorScheme.surfaceDim.toARGB32(),
      surfaceBrightArgb: colorScheme.surfaceBright.toARGB32(),
      surfaceContainerLowestArgb: colorScheme.surfaceContainerLowest.toARGB32(),
      surfaceContainerLowArgb: colorScheme.surfaceContainerLow.toARGB32(),
      surfaceContainerArgb: colorScheme.surfaceContainer.toARGB32(),
      surfaceContainerHighArgb: colorScheme.surfaceContainerHigh.toARGB32(),
      surfaceContainerHighestArgb: colorScheme.surfaceContainerHighest
          .toARGB32(),
      onSurfaceVariantArgb: colorScheme.onSurfaceVariant.toARGB32(),
      inverseSurfaceArgb: colorScheme.inverseSurface.toARGB32(),
      onInverseSurfaceArgb: colorScheme.onInverseSurface.toARGB32(),
      inversePrimaryArgb: colorScheme.inversePrimary.toARGB32(),
      shadowArgb: colorScheme.shadow.toARGB32(),
      scrimArgb: colorScheme.scrim.toARGB32(),
      surfaceTintArgb: colorScheme.surfaceTint.toARGB32(),
      surfaceVariantArgb: colorScheme.surfaceContainerHighest.toARGB32(),
    );
  }

  final int argb;
  final int primaryArgb;
  final int onPrimaryArgb;
  final int primaryContainerArgb;
  final int onPrimaryContainerArgb;
  final int primaryFixedArgb;
  final int primaryFixedDimArgb;
  final int onPrimaryFixedArgb;
  final int onPrimaryFixedVariantArgb;
  final int secondaryArgb;
  final int onSecondaryArgb;
  final int secondaryContainerArgb;
  final int onSecondaryContainerArgb;
  final int secondaryFixedArgb;
  final int secondaryFixedDimArgb;
  final int onSecondaryFixedArgb;
  final int onSecondaryFixedVariantArgb;
  final int tertiaryArgb;
  final int onTertiaryArgb;
  final int tertiaryContainerArgb;
  final int onTertiaryContainerArgb;
  final int tertiaryFixedArgb;
  final int tertiaryFixedDimArgb;
  final int onTertiaryFixedArgb;
  final int onTertiaryFixedVariantArgb;
  final int errorArgb;
  final int onErrorArgb;
  final int errorContainerArgb;
  final int onErrorContainerArgb;
  final int outlineArgb;
  final int outlineVariantArgb;
  final int surfaceArgb;
  final int onSurfaceArgb;
  final int surfaceDimArgb;
  final int surfaceBrightArgb;
  final int surfaceContainerLowestArgb;
  final int surfaceContainerLowArgb;
  final int surfaceContainerArgb;
  final int surfaceContainerHighArgb;
  final int surfaceContainerHighestArgb;
  final int onSurfaceVariantArgb;
  final int inverseSurfaceArgb;
  final int onInverseSurfaceArgb;
  final int inversePrimaryArgb;
  final int shadowArgb;
  final int scrimArgb;
  final int surfaceTintArgb;
  final int surfaceVariantArgb;

  material.Color get primary => material.Color(primaryArgb);
  material.Color get onPrimary => material.Color(onPrimaryArgb);
  material.Color get primaryContainer => material.Color(primaryContainerArgb);
  material.Color get onPrimaryContainer =>
      material.Color(onPrimaryContainerArgb);
  material.Color get primaryFixed => material.Color(primaryFixedArgb);
  material.Color get primaryFixedDim => material.Color(primaryFixedDimArgb);
  material.Color get onPrimaryFixed => material.Color(onPrimaryFixedArgb);
  material.Color get onPrimaryFixedVariant =>
      material.Color(onPrimaryFixedVariantArgb);
  material.Color get secondary => material.Color(secondaryArgb);
  material.Color get onSecondary => material.Color(onSecondaryArgb);
  material.Color get secondaryContainer =>
      material.Color(secondaryContainerArgb);
  material.Color get onSecondaryContainer =>
      material.Color(onSecondaryContainerArgb);
  material.Color get secondaryFixed => material.Color(secondaryFixedArgb);
  material.Color get secondaryFixedDim => material.Color(secondaryFixedDimArgb);
  material.Color get onSecondaryFixed => material.Color(onSecondaryFixedArgb);
  material.Color get onSecondaryFixedVariant =>
      material.Color(onSecondaryFixedVariantArgb);
  material.Color get tertiary => material.Color(tertiaryArgb);
  material.Color get onTertiary => material.Color(onTertiaryArgb);
  material.Color get tertiaryContainer => material.Color(tertiaryContainerArgb);
  material.Color get onTertiaryContainer =>
      material.Color(onTertiaryContainerArgb);
  material.Color get tertiaryFixed => material.Color(tertiaryFixedArgb);
  material.Color get tertiaryFixedDim => material.Color(tertiaryFixedDimArgb);
  material.Color get onTertiaryFixed => material.Color(onTertiaryFixedArgb);
  material.Color get onTertiaryFixedVariant =>
      material.Color(onTertiaryFixedVariantArgb);
  material.Color get error => material.Color(errorArgb);
  material.Color get onError => material.Color(onErrorArgb);
  material.Color get errorContainer => material.Color(errorContainerArgb);
  material.Color get onErrorContainer => material.Color(onErrorContainerArgb);
  material.Color get outline => material.Color(outlineArgb);
  material.Color get outlineVariant => material.Color(outlineVariantArgb);
  material.Color get surface => material.Color(surfaceArgb);
  material.Color get onSurface => material.Color(onSurfaceArgb);
  material.Color get surfaceDim => material.Color(surfaceDimArgb);
  material.Color get surfaceBright => material.Color(surfaceBrightArgb);
  material.Color get surfaceContainerLowest =>
      material.Color(surfaceContainerLowestArgb);
  material.Color get surfaceContainerLow =>
      material.Color(surfaceContainerLowArgb);
  material.Color get surfaceContainer => material.Color(surfaceContainerArgb);
  material.Color get surfaceContainerHigh =>
      material.Color(surfaceContainerHighArgb);
  material.Color get surfaceContainerHighest =>
      material.Color(surfaceContainerHighestArgb);
  material.Color get onSurfaceVariant => material.Color(onSurfaceVariantArgb);
  material.Color get inverseSurface => material.Color(inverseSurfaceArgb);
  material.Color get onInverseSurface => material.Color(onInverseSurfaceArgb);
  material.Color get inversePrimary => material.Color(inversePrimaryArgb);
  material.Color get shadow => material.Color(shadowArgb);
  material.Color get scrim => material.Color(scrimArgb);
  material.Color get surfaceTint => material.Color(surfaceTintArgb);
  material.Color get surfaceVariant => material.Color(surfaceVariantArgb);

  ColorScheme copyWith({
    int? argb,
    int? primaryArgb,
    int? onPrimaryArgb,
    int? primaryContainerArgb,
    int? onPrimaryContainerArgb,
    int? primaryFixedArgb,
    int? primaryFixedDimArgb,
    int? onPrimaryFixedArgb,
    int? onPrimaryFixedVariantArgb,
    int? secondaryArgb,
    int? onSecondaryArgb,
    int? secondaryContainerArgb,
    int? onSecondaryContainerArgb,
    int? secondaryFixedArgb,
    int? secondaryFixedDimArgb,
    int? onSecondaryFixedArgb,
    int? onSecondaryFixedVariantArgb,
    int? tertiaryArgb,
    int? onTertiaryArgb,
    int? tertiaryContainerArgb,
    int? onTertiaryContainerArgb,
    int? tertiaryFixedArgb,
    int? tertiaryFixedDimArgb,
    int? onTertiaryFixedArgb,
    int? onTertiaryFixedVariantArgb,
    int? errorArgb,
    int? onErrorArgb,
    int? errorContainerArgb,
    int? onErrorContainerArgb,
    int? outlineArgb,
    int? outlineVariantArgb,
    int? surfaceArgb,
    int? onSurfaceArgb,
    int? surfaceDimArgb,
    int? surfaceBrightArgb,
    int? surfaceContainerLowestArgb,
    int? surfaceContainerLowArgb,
    int? surfaceContainerArgb,
    int? surfaceContainerHighArgb,
    int? surfaceContainerHighestArgb,
    int? onSurfaceVariantArgb,
    int? inverseSurfaceArgb,
    int? onInverseSurfaceArgb,
    int? inversePrimaryArgb,
    int? shadowArgb,
    int? scrimArgb,
    int? surfaceTintArgb,
    int? surfaceVariantArgb,
  }) {
    return ColorScheme(
      argb: argb ?? this.argb,
      primaryArgb: primaryArgb ?? this.primaryArgb,
      onPrimaryArgb: onPrimaryArgb ?? this.onPrimaryArgb,
      primaryContainerArgb: primaryContainerArgb ?? this.primaryContainerArgb,
      onPrimaryContainerArgb:
          onPrimaryContainerArgb ?? this.onPrimaryContainerArgb,
      primaryFixedArgb: primaryFixedArgb ?? this.primaryFixedArgb,
      primaryFixedDimArgb: primaryFixedDimArgb ?? this.primaryFixedDimArgb,
      onPrimaryFixedArgb: onPrimaryFixedArgb ?? this.onPrimaryFixedArgb,
      onPrimaryFixedVariantArgb:
          onPrimaryFixedVariantArgb ?? this.onPrimaryFixedVariantArgb,
      secondaryArgb: secondaryArgb ?? this.secondaryArgb,
      onSecondaryArgb: onSecondaryArgb ?? this.onSecondaryArgb,
      secondaryContainerArgb:
          secondaryContainerArgb ?? this.secondaryContainerArgb,
      onSecondaryContainerArgb:
          onSecondaryContainerArgb ?? this.onSecondaryContainerArgb,
      secondaryFixedArgb: secondaryFixedArgb ?? this.secondaryFixedArgb,
      secondaryFixedDimArgb:
          secondaryFixedDimArgb ?? this.secondaryFixedDimArgb,
      onSecondaryFixedArgb: onSecondaryFixedArgb ?? this.onSecondaryFixedArgb,
      onSecondaryFixedVariantArgb:
          onSecondaryFixedVariantArgb ?? this.onSecondaryFixedVariantArgb,
      tertiaryArgb: tertiaryArgb ?? this.tertiaryArgb,
      onTertiaryArgb: onTertiaryArgb ?? this.onTertiaryArgb,
      tertiaryContainerArgb:
          tertiaryContainerArgb ?? this.tertiaryContainerArgb,
      onTertiaryContainerArgb:
          onTertiaryContainerArgb ?? this.onTertiaryContainerArgb,
      tertiaryFixedArgb: tertiaryFixedArgb ?? this.tertiaryFixedArgb,
      tertiaryFixedDimArgb: tertiaryFixedDimArgb ?? this.tertiaryFixedDimArgb,
      onTertiaryFixedArgb: onTertiaryFixedArgb ?? this.onTertiaryFixedArgb,
      onTertiaryFixedVariantArgb:
          onTertiaryFixedVariantArgb ?? this.onTertiaryFixedVariantArgb,
      errorArgb: errorArgb ?? this.errorArgb,
      onErrorArgb: onErrorArgb ?? this.onErrorArgb,
      errorContainerArgb: errorContainerArgb ?? this.errorContainerArgb,
      onErrorContainerArgb: onErrorContainerArgb ?? this.onErrorContainerArgb,
      outlineArgb: outlineArgb ?? this.outlineArgb,
      outlineVariantArgb: outlineVariantArgb ?? this.outlineVariantArgb,
      surfaceArgb: surfaceArgb ?? this.surfaceArgb,
      onSurfaceArgb: onSurfaceArgb ?? this.onSurfaceArgb,
      surfaceDimArgb: surfaceDimArgb ?? this.surfaceDimArgb,
      surfaceBrightArgb: surfaceBrightArgb ?? this.surfaceBrightArgb,
      surfaceContainerLowestArgb:
          surfaceContainerLowestArgb ?? this.surfaceContainerLowestArgb,
      surfaceContainerLowArgb:
          surfaceContainerLowArgb ?? this.surfaceContainerLowArgb,
      surfaceContainerArgb: surfaceContainerArgb ?? this.surfaceContainerArgb,
      surfaceContainerHighArgb:
          surfaceContainerHighArgb ?? this.surfaceContainerHighArgb,
      surfaceContainerHighestArgb:
          surfaceContainerHighestArgb ?? this.surfaceContainerHighestArgb,
      onSurfaceVariantArgb: onSurfaceVariantArgb ?? this.onSurfaceVariantArgb,
      inverseSurfaceArgb: inverseSurfaceArgb ?? this.inverseSurfaceArgb,
      onInverseSurfaceArgb: onInverseSurfaceArgb ?? this.onInverseSurfaceArgb,
      inversePrimaryArgb: inversePrimaryArgb ?? this.inversePrimaryArgb,
      shadowArgb: shadowArgb ?? this.shadowArgb,
      scrimArgb: scrimArgb ?? this.scrimArgb,
      surfaceTintArgb: surfaceTintArgb ?? this.surfaceTintArgb,
      surfaceVariantArgb: surfaceVariantArgb ?? this.surfaceVariantArgb,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'argb': argb,
      'primaryArgb': primaryArgb,
      'onPrimaryArgb': onPrimaryArgb,
      'primaryContainerArgb': primaryContainerArgb,
      'onPrimaryContainerArgb': onPrimaryContainerArgb,
      'primaryFixedArgb': primaryFixedArgb,
      'primaryFixedDimArgb': primaryFixedDimArgb,
      'onPrimaryFixedArgb': onPrimaryFixedArgb,
      'onPrimaryFixedVariantArgb': onPrimaryFixedVariantArgb,
      'secondaryArgb': secondaryArgb,
      'onSecondaryArgb': onSecondaryArgb,
      'secondaryContainerArgb': secondaryContainerArgb,
      'onSecondaryContainerArgb': onSecondaryContainerArgb,
      'secondaryFixedArgb': secondaryFixedArgb,
      'secondaryFixedDimArgb': secondaryFixedDimArgb,
      'onSecondaryFixedArgb': onSecondaryFixedArgb,
      'onSecondaryFixedVariantArgb': onSecondaryFixedVariantArgb,
      'tertiaryArgb': tertiaryArgb,
      'onTertiaryArgb': onTertiaryArgb,
      'tertiaryContainerArgb': tertiaryContainerArgb,
      'onTertiaryContainerArgb': onTertiaryContainerArgb,
      'tertiaryFixedArgb': tertiaryFixedArgb,
      'tertiaryFixedDimArgb': tertiaryFixedDimArgb,
      'onTertiaryFixedArgb': onTertiaryFixedArgb,
      'onTertiaryFixedVariantArgb': onTertiaryFixedVariantArgb,
      'errorArgb': errorArgb,
      'onErrorArgb': onErrorArgb,
      'errorContainerArgb': errorContainerArgb,
      'onErrorContainerArgb': onErrorContainerArgb,
      'outlineArgb': outlineArgb,
      'outlineVariantArgb': outlineVariantArgb,
      'surfaceArgb': surfaceArgb,
      'onSurfaceArgb': onSurfaceArgb,
      'surfaceDimArgb': surfaceDimArgb,
      'surfaceBrightArgb': surfaceBrightArgb,
      'surfaceContainerLowestArgb': surfaceContainerLowestArgb,
      'surfaceContainerLowArgb': surfaceContainerLowArgb,
      'surfaceContainerArgb': surfaceContainerArgb,
      'surfaceContainerHighArgb': surfaceContainerHighArgb,
      'surfaceContainerHighestArgb': surfaceContainerHighestArgb,
      'onSurfaceVariantArgb': onSurfaceVariantArgb,
      'inverseSurfaceArgb': inverseSurfaceArgb,
      'onInverseSurfaceArgb': onInverseSurfaceArgb,
      'inversePrimaryArgb': inversePrimaryArgb,
      'shadowArgb': shadowArgb,
      'scrimArgb': scrimArgb,
      'surfaceTintArgb': surfaceTintArgb,
      'surfaceVariantArgb': surfaceVariantArgb,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  List<Object?> get props => [
    argb,
    primaryArgb,
    onPrimaryArgb,
    primaryContainerArgb,
    onPrimaryContainerArgb,
    primaryFixedArgb,
    primaryFixedDimArgb,
    onPrimaryFixedArgb,
    onPrimaryFixedVariantArgb,
    secondaryArgb,
    onSecondaryArgb,
    secondaryContainerArgb,
    onSecondaryContainerArgb,
    secondaryFixedArgb,
    secondaryFixedDimArgb,
    onSecondaryFixedArgb,
    onSecondaryFixedVariantArgb,
    tertiaryArgb,
    onTertiaryArgb,
    tertiaryContainerArgb,
    onTertiaryContainerArgb,
    tertiaryFixedArgb,
    tertiaryFixedDimArgb,
    onTertiaryFixedArgb,
    onTertiaryFixedVariantArgb,
    errorArgb,
    onErrorArgb,
    errorContainerArgb,
    onErrorContainerArgb,
    outlineArgb,
    outlineVariantArgb,
    surfaceArgb,
    onSurfaceArgb,
    surfaceDimArgb,
    surfaceBrightArgb,
    surfaceContainerLowestArgb,
    surfaceContainerLowArgb,
    surfaceContainerArgb,
    surfaceContainerHighArgb,
    surfaceContainerHighestArgb,
    onSurfaceVariantArgb,
    inverseSurfaceArgb,
    onInverseSurfaceArgb,
    inversePrimaryArgb,
    shadowArgb,
    scrimArgb,
    surfaceTintArgb,
    surfaceVariantArgb,
  ];
}

class ColorSchemeConverter extends TypeConverter<ColorScheme?, String?>
    with JsonTypeConverter2<ColorScheme?, String?, String?> {
  const ColorSchemeConverter();

  @override
  ColorScheme? fromSql(String? fromDb) {
    if (fromDb == null) return null;
    return ColorScheme.fromJson(fromDb);
  }

  @override
  String? toSql(ColorScheme? value) {
    if (value == null) return null;
    return value.toJson();
  }

  @override
  ColorScheme? fromJson(String? json) {
    if (json == null) return null;
    return ColorScheme.fromJson(json);
  }

  @override
  String? toJson(ColorScheme? value) {
    if (value == null) return null;
    return value.toJson();
  }
}
