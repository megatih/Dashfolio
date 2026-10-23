import 'package:decimal/decimal.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashfolio/domain/services/allocation.dart';
import 'package:dashfolio/domain/services/fx.dart';
import 'package:dashfolio/domain/services/holdings_engine.dart';
import 'package:dashfolio/domain/services/valuation.dart';

import '../support/builders.dart';

Quote q(String s, double price, double prev, {String ccy = 'USD', String type = 'EQUITY', String? sector}) =>
    Quote(symbol: s, price: price, previousClose: prev, currency: ccy, quoteType: type, sector: sector, fetchedAt: DateTime.utc(2024));

void main() {
  const engine = HoldingsEngine();
  const valuation = Valuation();

  test('QuoteFxRates direct, inverse, usd shorthand and triangulation', () {
    final fx = QuoteFxRates({'EURUSD=X': 1.25, 'JPY=X': 100, 'GBPUSD=X': 1.5});
    expect(fx.rate('USD', 'USD'), Decimal.one);
    expect(fx.rate('EUR', 'USD'), D('1.25'));
    expect(fx.rate('USD', 'EUR'), D('0.8'));
    expect(fx.rate('USD', 'JPY'), D('100'));
    expect(fx.rate('EUR', 'GBP')!.toDouble(), closeTo(1.25 / 1.5, 1e-9));
    expect(fx.rate('EUR', 'CHF'), isNull);
  });

  test('values holdings in base currency with day change and unrealized P&L', () {
    final pos = engine.replay([
      buy('AAPL', '2024-01-02', 10, 100),
      buy('SAP.DE', '2024-01-02', 10, 100, currency: 'EUR', fx: '1.10'),
    ], CostMethod.average);
    final quotes = {'AAPL': q('AAPL', 120, 110), 'SAP.DE': q('SAP.DE', 110, 100, ccy: 'EUR')};
    final fx = QuoteFxRates({'EURUSD=X': 1.2});
    final v = valuation.value(pos, quotes, fx, 'USD');

    final aapl = v.holdings.firstWhere((h) => h.symbol == 'AAPL');
    final sap = v.holdings.firstWhere((h) => h.symbol == 'SAP.DE');
    expect(aapl.marketValueBase, D('1200'));
    expect(aapl.dayChangeBase, D('100'));
    expect(aapl.unrealizedBase, D('200'));
    expect(sap.marketValueBase, D('1320')); // 10*110*1.2
    expect(sap.costBase, D('1100'));
    expect(sap.dayChangeBase, D('120'));

    expect(v.totals.value, D('2520'));
    expect(v.totals.costBasis, D('2100'));
    expect(v.totals.unrealized, D('420'));
    expect(v.totals.dayChange, D('220'));
    expect((aapl.weight + sap.weight).toDouble(), closeTo(1, 1e-9));
  });

  test('missing price falls back to cost and is flagged', () {
    final pos = engine.replay([buy('X', '2024-01-02', 10, 5)], CostMethod.average);
    final v = valuation.value(pos, {}, const IdentityFx(), 'USD');
    expect(v.holdings.single.priceMissing, isTrue);
    expect(v.holdings.single.marketValueBase, D('50'));
  });

  test('closed positions keep realized P&L but not value', () {
    final pos = engine.replay([buy('X', '2024-01-02', 10, 5), sell('X', '2024-01-03', 10, 6)], CostMethod.average);
    final v = valuation.value(pos, {'X': q('X', 7, 7)}, const IdentityFx(), 'USD');
    expect(v.holdings, isEmpty);
    expect(v.closed.single.realizedBase, D('10'));
    expect(v.totals.realized, D('10'));
    expect(v.totals.value, Decimal.zero);
  });

  test('merge combines the same symbol across portfolios', () {
    final a = valuation.value(
      engine.replay([buy('X', '2024-01-02', 10, 5)], CostMethod.average),
      {'X': q('X', 6, 5)},
      const IdentityFx(),
      'USD',
    );
    final b = valuation.value(
      engine.replay([buy('X', '2024-01-02', 5, 7)], CostMethod.average),
      {'X': q('X', 6, 5)},
      const IdentityFx(),
      'USD',
    );
    final merged = valuation.merge([a.holdings, b.holdings]);
    expect(merged.length, 1);
    expect(merged.single.quantity, D('15'));
    expect(merged.single.marketValueBase, D('90'));
    expect(merged.single.costBase, D('85'));
    expect(merged.single.weight, Decimal.one);
  });

  group('allocation', () {
    final pos = engine.replay([
      buy('AAPL', '2024-01-02', 10, 100),
      buy('SPY', '2024-01-02', 10, 100),
      buy('BTC-USD', '2024-01-02', 1, 100),
    ], CostMethod.average);
    final v = valuation.value(
      pos,
      {
        'AAPL': q('AAPL', 60, 60, sector: 'Technology'),
        'SPY': q('SPY', 30, 30, type: 'ETF'),
        'BTC-USD': q('BTC-USD', 100, 100, type: 'CRYPTOCURRENCY'),
      },
      const IdentityFx(),
      'USD',
    );

    test('groups by asset class with weights summing to one', () {
      final s = const Allocation().group(v.holdings, AllocationGroup.assetClass);
      expect(s.first.label, 'Stocks');
      expect(s.fold(Decimal.zero, (a, e) => a + e.weight).toDouble(), closeTo(1, 1e-9));
      expect(s.map((e) => e.label), containsAll(['Stocks', 'ETFs', 'Crypto']));
    });

    test('collapses small slices into Other', () {
      final slices = const Allocation().group(v.holdings, AllocationGroup.holding);
      final c = const Allocation().collapseSmall(slices, threshold: 0.35);
      expect(c.any((s) => s.isOther), isTrue);
    });
  });
}
