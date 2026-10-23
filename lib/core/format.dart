import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'decimal_ext.dart';

/// Locale-aware number/currency/date formatting helpers.
class Fmt {
  const Fmt._();

  static String currency(Decimal value, String code, {bool compact = false, bool signed = false}) {
    final v = value.toDouble();
    final f = compact ? NumberFormat.compactSimpleCurrency(name: code) : NumberFormat.simpleCurrency(name: code);
    final s = f.format(v.abs());
    final neg = value.isNegative && v != 0;
    if (neg) return '-$s';
    return signed && v > 0 ? '+$s' : s;
  }

  static String number(Decimal value, {int maxDecimals = 4}) {
    final f = NumberFormat.decimalPatternDigits(decimalDigits: 0)..maximumFractionDigits = maxDecimals;
    return f.format(value.toDouble());
  }

  static String price(double? v, {int decimals = 2}) {
    if (v == null) return '—';
    return NumberFormat.decimalPatternDigits(decimalDigits: decimals).format(v);
  }

  static String percent(Decimal? ratio, {bool signed = true, int decimals = 2}) {
    if (ratio == null) return '—';
    final v = ratio.toDouble() * 100;
    final s = NumberFormat.decimalPatternDigits(decimalDigits: decimals).format(v.abs());
    final sign = v < 0 ? '-' : (signed && v > 0 ? '+' : '');
    return '$sign$s%';
  }

  static String compact(num? v) {
    if (v == null) return '—';
    return NumberFormat.compact().format(v);
  }

  static String date(DateTime d) => DateFormat.yMMMd().format(d);
  static String shortDate(DateTime d) => DateFormat.MMMd().format(d);
  static String monthYear(DateTime d) => DateFormat.yMMM().format(d);
  static String time(DateTime d) => DateFormat.jm().format(d);
  static String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
