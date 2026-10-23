import 'package:decimal/decimal.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashfolio/domain/services/fx.dart';
import 'package:dashfolio/domain/services/value_history.dart';

import '../support/builders.dart';

DateTime d(String s) => DateTime.parse('${s}T00:00:00Z');

void main() {
  const vh = ValueHistory();
  final now = DateTime.utc(2024, 1, 10, 15);

  test('values holdings daily with forward fill over weekends', () {
    final r = vh.compute(
      transactions: [buy('X', '2024-01-02', 10, 10)],
      prices: {
        'X': PriceSeries([d('2024-01-02'), d('2024-01-03'), d('2024-01-04'), d('2024-01-05'), d('2024-01-08')], [10, 11, 12, 13, 14]),
      },
      symbolCurrency: {'X': 'USD'},
      fxToBase: {},
      base: 'USD',
      range: HistoryRange.max,
      now: now,
    );
    expect(r.points.first.date, d('2024-01-02'));
    expect(r.points.last.date, d('2024-01-10'));
    final byDate = {for (final p in r.points) p.date: p.value};
    expect(byDate[d('2024-01-02')], 100);
    expect(byDate[d('2024-01-05')], 130);
    expect(byDate[d('2024-01-06')], 130); // Saturday forward-filled
    expect(byDate[d('2024-01-10')], 140);
    expect(r.incomplete, isFalse);
  });

  test('range start is clipped to first transaction', () {
    final r = vh.compute(
      transactions: [buy('X', '2024-01-08', 1, 10)],
      prices: {
        'X': PriceSeries([d('2024-01-02')], [10]),
      },
      symbolCurrency: {'X': 'USD'},
      fxToBase: {},
      base: 'USD',
      range: HistoryRange.m1,
      now: now,
    );
    expect(r.points.first.date, d('2024-01-08'));
  });

  test('sells reduce value and missing prices flag incomplete', () {
    final r = vh.compute(
      transactions: [buy('X', '2024-01-02', 10, 10), sell('X', '2024-01-04', 10, 12), buy('Y', '2024-01-02', 1, 5)],
      prices: {
        'X': PriceSeries([d('2024-01-02')], [10]),
      },
      symbolCurrency: {'X': 'USD', 'Y': 'USD'},
      fxToBase: {},
      base: 'USD',
      range: HistoryRange.max,
      now: now,
    );
    final byDate = {for (final p in r.points) p.date: p.value};
    expect(byDate[d('2024-01-03')], 100);
    expect(byDate[d('2024-01-04')], 0);
    expect(r.incomplete, isTrue);
  });

  test('applies historical FX to non-base currency holdings', () {
    final r = vh.compute(
      transactions: [buy('E', '2024-01-02', 10, 10, currency: 'EUR')],
      prices: {
        'E': PriceSeries([d('2024-01-02')], [10]),
      },
      symbolCurrency: {'E': 'EUR'},
      fxToBase: {
        'EUR': FxSeries([d('2024-01-02'), d('2024-01-05')], [Decimal.parse('1.0'), Decimal.parse('1.5')]),
      },
      base: 'USD',
      range: HistoryRange.max,
      now: now,
    );
    final byDate = {for (final p in r.points) p.date: p.value};
    expect(byDate[d('2024-01-03')], 100);
    expect(byDate[d('2024-01-06')], 150);
  });

  test('pre-split quantities are restated to match split-adjusted closes', () {
    // Bought 10 shares; 10:1 split on Jan 5. Yahoo closes are split-adjusted (~$10 throughout).
    final r = vh.compute(
      transactions: [buy('S', '2024-01-02', 10, 100), splitTx('S', '2024-01-05', 10, 1)],
      prices: {
        'S': PriceSeries([d('2024-01-02')], [10]),
      },
      symbolCurrency: {'S': 'USD'},
      fxToBase: {},
      base: 'USD',
      range: HistoryRange.max,
      now: now,
    );
    final byDate = {for (final p in r.points) p.date: p.value};
    expect(byDate[d('2024-01-03')], 1000); // 10 shares * 10 split = 100 * $10
    expect(byDate[d('2024-01-08')], 1000); // no jump across the split
  });

  test('downsamples long ranges to maxPoints', () {
    final r = vh.compute(
      transactions: [buy('X', '2000-01-03', 1, 1)],
      prices: {
        'X': PriceSeries([d('2000-01-03')], [1]),
      },
      symbolCurrency: {'X': 'USD'},
      fxToBase: {},
      base: 'USD',
      range: HistoryRange.max,
      now: now,
      maxPoints: 300,
    );
    expect(r.points.length, lessThanOrEqualTo(302));
    expect(r.points.last.date, d('2024-01-10'));
  });
}
