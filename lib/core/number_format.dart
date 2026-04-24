import 'dart:math' as math;
import 'big_num.dart';

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

  /// Format a BigNum. Same suffix scheme as `format(double)` but handles
  /// magnitudes far beyond double range.
  static String formatBig(BigNum value) {
    if (value.isZero) return '0';
    if (value.isNegative) return '-${formatBig(value.negate())}';
    // value = m * 10^e with m in [1, 10)
    // Small numbers (e < 3) — render via double path for consistent output
    if (value.e < 3) return format(value.toDouble());
    final tier = value.e ~/ 3;
    final remainder = value.e - tier * 3;
    final display = value.m * math.pow(10, remainder).toDouble();
    return '${display.toStringAsFixed(2)}${_suffix(tier)}';
  }

  static String _suffix(int tier) {
    if (tier < _shortSuffixes.length) return _shortSuffixes[tier];
    final idx = tier - _shortSuffixes.length;
    final c1 = idx ~/ 26;
    final c2 = idx % 26;
    return '${String.fromCharCode(97 + c1)}${String.fromCharCode(97 + c2)}';
  }
}
