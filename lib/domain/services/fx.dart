import 'package:decimal/decimal.dart';

import '../../core/decimal_ext.dart';

/// Resolves exchange rates between currencies.
abstract class FxRates {
  /// Rate converting 1 unit of [from] into [to], or null if unknown.
  Decimal? rate(String from, String to);
}

class IdentityFx implements FxRates {
  const IdentityFx();
  @override
  Decimal? rate(String from, String to) => from == to ? Decimal.one : null;
}

/// Yahoo-style FX symbol for converting [from] → [to] (e.g. `EURUSD=X`).
String fxSymbol(String from, String to) => '$from$to=X';

/// FX table backed by a map of Yahoo FX quotes (symbol → price).
///
/// Lookup order: direct pair, inverse pair, USD shorthand (`JPY=X`), then
/// triangulation through USD.
class QuoteFxRates implements FxRates {
  QuoteFxRates(Map<String, double> prices) : _prices = prices;

  final Map<String, double> _prices;

  Decimal? _direct(String from, String to) {
    final p = _prices[fxSymbol(from, to)] ?? (from == 'USD' ? _prices['$to=X'] : null);
    if (p == null || p <= 0) return null;
    return dec(p);
  }

  Decimal? _oneHop(String from, String to) {
    final d = _direct(from, to);
    if (d != null) return d;
    final i = _direct(to, from);
    if (i != null && i != Decimal.zero) return Decimal.one.div(i);
    return null;
  }

  @override
  Decimal? rate(String from, String to) {
    if (from == to) return Decimal.one;
    final hop = _oneHop(from, to);
    if (hop != null) return hop;
    if (from != 'USD' && to != 'USD') {
      final a = _oneHop(from, 'USD');
      final b = _oneHop('USD', to);
      if (a != null && b != null) return a * b;
    }
    return null;
  }
}

/// Time series of FX rates (currency → base) for historical valuation.
class FxSeries {
  FxSeries(this.dates, this.rates) : assert(dates.length == rates.length);

  final List<DateTime> dates;
  final List<Decimal> rates;

  static FxSeries constant(Decimal rate) => FxSeries([], [rate]);

  /// Rate on or before [date] (forward fill); falls back to the first rate.
  Decimal? at(DateTime date) {
    if (rates.isEmpty) return null;
    if (dates.isEmpty) return rates.first;
    var lo = 0, hi = dates.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (!dates[mid].isAfter(date)) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return rates[found < 0 ? 0 : found];
  }
}
