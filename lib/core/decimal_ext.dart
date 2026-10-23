import 'package:decimal/decimal.dart';

extension DecimalX on Decimal {
  double get d => toDouble();

  bool get isNegative => sign < 0;

  Decimal get abs => isNegative ? -this : this;

  /// Divides and returns a [Decimal] (rational → scaled to [scale] digits).
  Decimal div(Decimal other, {int scale = 12}) {
    if (other == Decimal.zero) return Decimal.zero;
    return (this / other).toDecimal(scaleOnInfinitePrecision: scale);
  }
}

Decimal dec(Object? v) {
  if (v == null) return Decimal.zero;
  if (v is Decimal) return v;
  if (v is int) return Decimal.fromInt(v);
  if (v is double) {
    if (v.isNaN || v.isInfinite) return Decimal.zero;
    return Decimal.parse(v.toString().contains('e') ? v.toStringAsFixed(10) : v.toString());
  }
  return Decimal.tryParse(v.toString()) ?? Decimal.zero;
}

Decimal? decOrNull(Object? v) {
  if (v == null) return null;
  if (v is Decimal) return v;
  if (v is num) {
    if (v.isNaN || v.isInfinite) return null;
    return dec(v);
  }
  return Decimal.tryParse(v.toString());
}
