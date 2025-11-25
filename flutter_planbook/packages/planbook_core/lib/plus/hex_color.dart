import 'dart:ui';

extension HexColor on Color {
  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${(255 * a).toInt().toRadixString(16).padLeft(2, '0')}'
      '${(255 * r).toInt().toRadixString(16).padLeft(2, '0')}'
      '${(255 * g).toInt().toRadixString(16).padLeft(2, '0')}'
      '${(255 * b).toInt().toRadixString(16).padLeft(2, '0')}';
}

extension HexColorPlus on String {
  int toArgb() {
    final buffer = StringBuffer();
    if (length == 6 || length == 7) buffer.write('ff');
    buffer.write(replaceFirst('#', ''));
    return int.tryParse(buffer.toString(), radix: 16) ?? 0xffffffff;
  }

  Color get toColor => Color(toArgb());
}

extension HexColorInt on int {
  String toHex() => '#${toRadixString(16).padLeft(8, 'F').toUpperCase()}';
}
