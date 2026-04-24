class NumberFormatter {
  static const _shortSuffixes = ['', 'K', 'M', 'B', 'T'];

  static String format(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    if (value < 0) return '-${format(-value)}';
    if (value < 1000) return value.floor().toString();

    int tier = 0;
    double v = value;
    while (v >= 1000) {
      v /= 1000;
      tier++;
      if (tier >= _shortSuffixes.length + 26 * 26) break;
    }
    return '${v.toStringAsFixed(2)}${_suffix(tier)}';
  }

  static String formatPrecise(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    if (value < 0) return '-${formatPrecise(-value)}';
    if (value < 1000) {
      if (value == value.truncateToDouble()) return value.toInt().toString();
      return value.toStringAsFixed(1);
    }
    return format(value);
  }

  static String _suffix(int tier) {
    if (tier < _shortSuffixes.length) return _shortSuffixes[tier];
    final idx = tier - _shortSuffixes.length;
    final c1 = idx ~/ 26;
    final c2 = idx % 26;
    return '${String.fromCharCode(97 + c1)}${String.fromCharCode(97 + c2)}';
  }
}
