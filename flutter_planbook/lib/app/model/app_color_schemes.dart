import 'package:flutter/material.dart';

extension AppColorSchemesExtension on BuildContext {
  List<ColorScheme> get colorSchemes => [
    redColorScheme,
    blueColorScheme,
    amberColorScheme,
    greenColorScheme,
    yellowColorScheme,
    pinkColorScheme,
    orangeColorScheme,
    brownColorScheme,
    greyColorScheme,
    blueGreyColorScheme,
    purpleColorScheme,
    indigoColorScheme,
    tealColorScheme,
    cyanColorScheme,
    limeColorScheme,
  ];

  ColorScheme get redColorScheme => Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.redDark
      : AppColorSchemes.redLight;
  ColorScheme get blueColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.blueDark
      : AppColorSchemes.blueLight;
  ColorScheme get amberColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.amberDark
      : AppColorSchemes.amberLight;
  ColorScheme get greenColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.greenDark
      : AppColorSchemes.greenLight;
  ColorScheme get yellowColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.yellowDark
      : AppColorSchemes.yellowLight;
  ColorScheme get orangeColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.orangeDark
      : AppColorSchemes.orangeLight;
  ColorScheme get brownColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.brownDark
      : AppColorSchemes.brownLight;
  ColorScheme get greyColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.greyDark
      : AppColorSchemes.greyLight;
  ColorScheme get blueGreyColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.blueGreyDark
      : AppColorSchemes.blueGreyLight;
  ColorScheme get purpleColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.purpleDark
      : AppColorSchemes.purpleLight;
  ColorScheme get indigoColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.indigoDark
      : AppColorSchemes.indigoLight;
  ColorScheme get tealColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.tealDark
      : AppColorSchemes.tealLight;
  ColorScheme get cyanColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.cyanDark
      : AppColorSchemes.cyanLight;
  ColorScheme get limeColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.limeDark
      : AppColorSchemes.limeLight;
  ColorScheme get pinkColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorSchemes.pinkDark
      : AppColorSchemes.pinkLight;
}

class AppColorSchemes {
  // Red
  static ColorScheme redLight = ColorScheme.fromSeed(seedColor: Colors.red);
  static ColorScheme redDark = ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.dark,
  );

  // Pink
  static ColorScheme pinkLight = ColorScheme.fromSeed(seedColor: Colors.pink);
  static ColorScheme pinkDark = ColorScheme.fromSeed(
    seedColor: Colors.pink,
    brightness: Brightness.dark,
  );

  // Purple
  static ColorScheme purpleLight = ColorScheme.fromSeed(
    seedColor: Colors.purple,
  );
  static ColorScheme purpleDark = ColorScheme.fromSeed(
    seedColor: Colors.purple,
    brightness: Brightness.dark,
  );

  // Deep Purple
  static ColorScheme deepPurpleLight = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
  );
  static ColorScheme deepPurpleDark = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  );

  // Indigo
  static ColorScheme indigoLight = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
  );
  static ColorScheme indigoDark = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );

  // Blue
  static ColorScheme blueLight = ColorScheme.fromSeed(seedColor: Colors.blue);
  static ColorScheme blueDark = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  );

  // Light Blue
  static ColorScheme lightBlueLight = ColorScheme.fromSeed(
    seedColor: Colors.lightBlue,
  );
  static ColorScheme lightBlueDark = ColorScheme.fromSeed(
    seedColor: Colors.lightBlue,
    brightness: Brightness.dark,
  );

  // Cyan
  static ColorScheme cyanLight = ColorScheme.fromSeed(seedColor: Colors.cyan);
  static ColorScheme cyanDark = ColorScheme.fromSeed(
    seedColor: Colors.cyan,
    brightness: Brightness.dark,
  );

  // Teal
  static ColorScheme tealLight = ColorScheme.fromSeed(seedColor: Colors.teal);
  static ColorScheme tealDark = ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.dark,
  );

  // Green
  static ColorScheme greenLight = ColorScheme.fromSeed(seedColor: Colors.green);
  static ColorScheme greenDark = ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.dark,
  );

  // Light Green
  static ColorScheme lightGreenLight = ColorScheme.fromSeed(
    seedColor: Colors.lightGreen,
  );
  static ColorScheme lightGreenDark = ColorScheme.fromSeed(
    seedColor: Colors.lightGreen,
    brightness: Brightness.dark,
  );

  // Lime
  static ColorScheme limeLight = ColorScheme.fromSeed(seedColor: Colors.lime);
  static ColorScheme limeDark = ColorScheme.fromSeed(
    seedColor: Colors.lime,
    brightness: Brightness.dark,
  );

  // Yellow
  static ColorScheme yellowLight = ColorScheme.fromSeed(
    seedColor: Colors.yellow,
  );
  static ColorScheme yellowDark = ColorScheme.fromSeed(
    seedColor: Colors.yellow,
    brightness: Brightness.dark,
  );

  // Amber
  static ColorScheme amberLight = ColorScheme.fromSeed(seedColor: Colors.amber);
  static ColorScheme amberDark = ColorScheme.fromSeed(
    seedColor: Colors.amber,
    brightness: Brightness.dark,
  );

  // Orange
  static ColorScheme orangeLight = ColorScheme.fromSeed(
    seedColor: Colors.orange,
  );
  static ColorScheme orangeDark = ColorScheme.fromSeed(
    seedColor: Colors.orange,
    brightness: Brightness.dark,
  );

  // Deep Orange
  static ColorScheme deepOrangeLight = ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
  );
  static ColorScheme deepOrangeDark = ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
    brightness: Brightness.dark,
  );

  // Brown
  static ColorScheme brownLight = ColorScheme.fromSeed(seedColor: Colors.brown);
  static ColorScheme brownDark = ColorScheme.fromSeed(
    seedColor: Colors.brown,
    brightness: Brightness.dark,
  );

  // Grey
  static ColorScheme greyLight = ColorScheme.fromSeed(seedColor: Colors.grey);
  static ColorScheme greyDark = ColorScheme.fromSeed(
    seedColor: Colors.grey,
    brightness: Brightness.dark,
  );

  // Blue Grey
  static ColorScheme blueGreyLight = ColorScheme.fromSeed(
    seedColor: Colors.blueGrey,
  );
  static ColorScheme blueGreyDark = ColorScheme.fromSeed(
    seedColor: Colors.blueGrey,
    brightness: Brightness.dark,
  );
}
