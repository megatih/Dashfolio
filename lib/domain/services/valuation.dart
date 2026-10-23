import 'package:decimal/decimal.dart';

import '../../core/decimal_ext.dart';
import '../entities/market.dart';
import 'fx.dart';
import 'holdings_engine.dart';

/// A valued holding, expressed in the base currency unless suffixed `Local`.
class HoldingValuation {
  HoldingValuation({
    required this.symbol,
    required this.name,
    required this.currency,
    required this.quantity,
    required this.costLocal,
    required this.costBase,
    required this.marketValueBase,
    required this.dayChangeBase,
    required this.realizedBase,
    required this.dividendsBase,
    this.priceLocal,
    this.previousCloseLocal,
    this.quote,
    this.position,
    this.priceMissing = false,
    this.fxMissing = false,
    Decimal? weight,
  }) : weight = weight ?? Decimal.zero;

  final String symbol;
  final String name;
  final String currency;
  final Decimal quantity;
  final Decimal costLocal;
  final Decimal costBase;
  final Decimal marketValueBase;
  final Decimal dayChangeBase;
  final Decimal realizedBase;
  final Decimal dividendsBase;
  final Decimal? priceLocal;
  final Decimal? previousCloseLocal;
  final Quote? quote;
  final Position? position;
  final bool priceMissing;
  final bool fxMissing;
  Decimal weight;

  Decimal get avgCostLocal => quantity == Decimal.zero ? Decimal.zero : costLocal.div(quantity);
  Decimal get unrealizedBase => marketValueBase - costBase;
  Decimal? get unrealizedPct => costBase == Decimal.zero ? null : unrealizedBase.div(costBase);
  Decimal? get dayChangePct {
    final prev = marketValueBase - dayChangeBase;
    return prev == Decimal.zero ? null : dayChangeBase.div(prev);
  }
}

class PortfolioTotals {
  const PortfolioTotals({
    required this.value,
    required this.costBasis,
    required this.dayChange,
    required this.realized,
    required this.dividends,
    required this.cash,
    required this.hasCash,
  });

  static final empty = PortfolioTotals(
    value: Decimal.zero,
    costBasis: Decimal.zero,
    dayChange: Decimal.zero,
    realized: Decimal.zero,
    dividends: Decimal.zero,
    cash: Decimal.zero,
    hasCash: false,
  );

  final Decimal value;
  final Decimal costBasis;
  final Decimal dayChange;
  final Decimal realized;
  final Decimal dividends;
  final Decimal cash;
  final bool hasCash;

  Decimal get unrealized => value - costBasis;
  Decimal? get unrealizedPct => costBasis == Decimal.zero ? null : unrealized.div(costBasis);
  Decimal? get dayChangePct {
    final prev = value - dayChange;
    return prev == Decimal.zero ? null : dayChange.div(prev);
  }

  Decimal get totalReturn => unrealized + realized + dividends;
  Decimal? get totalReturnPct => costBasis == Decimal.zero ? null : totalReturn.div(costBasis);
  Decimal get netWorth => hasCash ? value + cash : value;

  PortfolioTotals operator +(PortfolioTotals o) => PortfolioTotals(
    value: value + o.value,
    costBasis: costBasis + o.costBasis,
    dayChange: dayChange + o.dayChange,
    realized: realized + o.realized,
    dividends: dividends + o.dividends,
    cash: cash + o.cash,
    hasCash: hasCash || o.hasCash,
  );
}

class ValuedPortfolio {
  ValuedPortfolio(this.holdings, this.totals, this.closed);

  final List<HoldingValuation> holdings;
  final PortfolioTotals totals;

  /// Closed positions (no quantity left) that still carry realized P&L / dividends.
  final List<HoldingValuation> closed;
}

class Valuation {
  const Valuation();

  /// Values [positions] using [quotes] (by symbol) and [fx], converting to [base].
  ValuedPortfolio value(
    PortfolioPositions positions,
    Map<String, Quote> quotes,
    FxRates fx,
    String base, {
    Map<String, String> names = const {},
  }) {
    final holdings = <HoldingValuation>[];
    final closed = <HoldingValuation>[];

    for (final p in positions.positions.values) {
      final quote = quotes[p.symbol];
      final currency = quote?.currency ?? p.currency;
      final rate = fx.rate(currency, base);
      final fxMissing = rate == null;
      final r = rate ?? Decimal.one;
      final price = quote?.price == null ? null : dec(quote!.price);
      final prev = quote?.previousClose == null ? null : dec(quote!.previousClose);
      final priceMissing = price == null;

      final mv = p.isOpen ? (priceMissing ? p.costBase : p.quantity * price * r) : Decimal.zero;
      final dayChange = (p.isOpen && !priceMissing && prev != null) ? p.quantity * (price - prev) * r : Decimal.zero;

      final h = HoldingValuation(
        symbol: p.symbol,
        name: quote?.name ?? names[p.symbol] ?? p.symbol,
        currency: currency,
        quantity: p.quantity,
        costLocal: p.costLocal,
        costBase: p.costBase,
        marketValueBase: mv,
        dayChangeBase: dayChange,
        realizedBase: p.realizedBase,
        dividendsBase: p.dividendsBase,
        priceLocal: price,
        previousCloseLocal: prev,
        quote: quote,
        position: p,
        priceMissing: p.isOpen && priceMissing,
        fxMissing: fxMissing,
      );
      (p.isOpen ? holdings : closed).add(h);
    }

    final total = holdings.fold(Decimal.zero, (s, h) => s + h.marketValueBase);
    for (final h in holdings) {
      h.weight = total == Decimal.zero ? Decimal.zero : h.marketValueBase.div(total);
    }

    final totals = PortfolioTotals(
      value: total,
      costBasis: holdings.fold(Decimal.zero, (s, h) => s + h.costBase),
      dayChange: holdings.fold(Decimal.zero, (s, h) => s + h.dayChangeBase),
      realized: positions.realizedBase,
      dividends: positions.dividendsBase,
      cash: positions.cashBase,
      hasCash: positions.hasCashActivity,
    );
    return ValuedPortfolio(holdings, totals, closed);
  }

  /// Merges valued holdings from several portfolios into one list keyed by symbol.
  List<HoldingValuation> merge(Iterable<List<HoldingValuation>> lists) {
    final bySymbol = <String, List<HoldingValuation>>{};
    for (final list in lists) {
      for (final h in list) {
        bySymbol.putIfAbsent(h.symbol, () => []).add(h);
      }
    }
    final merged = bySymbol.values.map((hs) {
      if (hs.length == 1) return hs.first;
      final first = hs.first;
      Decimal sum(Decimal Function(HoldingValuation) f) => hs.fold(Decimal.zero, (s, h) => s + f(h));
      return HoldingValuation(
        symbol: first.symbol,
        name: first.name,
        currency: first.currency,
        quantity: sum((h) => h.quantity),
        costLocal: sum((h) => h.costLocal),
        costBase: sum((h) => h.costBase),
        marketValueBase: sum((h) => h.marketValueBase),
        dayChangeBase: sum((h) => h.dayChangeBase),
        realizedBase: sum((h) => h.realizedBase),
        dividendsBase: sum((h) => h.dividendsBase),
        priceLocal: first.priceLocal,
        previousCloseLocal: first.previousCloseLocal,
        quote: first.quote,
        priceMissing: hs.any((h) => h.priceMissing),
        fxMissing: hs.any((h) => h.fxMissing),
      );
    }).toList();
    final total = merged.fold(Decimal.zero, (s, h) => s + h.marketValueBase);
    for (final h in merged) {
      h.weight = total == Decimal.zero ? Decimal.zero : h.marketValueBase.div(total);
    }
    return merged;
  }
}
