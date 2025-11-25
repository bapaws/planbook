extension DoubleX on double {
  String toIntString(int fractionDigits) {
    if (fractionDigits < 0) {
      throw ArgumentError('fractionDigits must be non-negative');
    }

    if (fractionDigits == 0) {
      return toInt().toString();
    }

    final factor = 10.0 * fractionDigits;
    final rounded = (this * factor).round() / factor;
    final str = rounded.toStringAsFixed(fractionDigits);

    // 去掉末尾的 0
    if (str.contains('.')) {
      return str.replaceAll(RegExp(r'\.?0+$'), '');
    }
    return str;
  }
}
