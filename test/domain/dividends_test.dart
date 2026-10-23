import 'package:decimal/decimal.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashfolio/domain/services/dividends.dart';

import '../support/builders.dart';

DateTime d(String s) => DateTime.parse('${s}T00:00:00Z');

void main() {
  const svc = DividendService();
  final now = DateTime.utc(2024, 12, 15);

  test('monthly buckets cover trailing 12 months, zero filled', () {
    final txs = [dividendTx('X', '2024-12-02', 10, 0.5), dividendTx('X', '2024-11-02', 10, 0.5), dividendTx('X', '2023-01-02', 10, 9)];
    final m = svc.monthly(txs, now);
    expect(m.length, 12);
    expect(m.last.month, DateTime.utc(2024, 12, 1));
    expect(m.last.amountBase, D('5'));
    expect(m.fold(Decimal.zero, (s, e) => s + e.amountBase), D('10')); // 2023-01 excluded
  });

  test('bySymbol ranks by amount and converts with stored fx', () {
    final txs = [dividendTx('A', '2024-03-01', 10, 1, currency: 'EUR', fx: '2'), dividendTx('B', '2024-03-01', 10, 1)];
    final s = svc.bySymbol(txs);
    expect(s.first.symbol, 'A');
    expect(s.first.amountBase, D('20'));
  });

  test('detects unrecorded dividends held on the ex-date only', () {
    final txs = [buy('X', '2024-02-01', 10, 50), sell('X', '2024-08-01', 10, 55)];
    final events = {
      'X': [
        DividendEvent(symbol: 'X', exDate: d('2024-01-15'), amount: 0.5), // before purchase
        DividendEvent(symbol: 'X', exDate: d('2024-05-15'), amount: 0.5), // held
        DividendEvent(symbol: 'X', exDate: d('2024-11-15'), amount: 0.5), // already sold
      ],
    };
    final out = svc.detect(byPortfolio: {1: txs}, events: events, currencies: {'X': 'USD'}, now: now);
    expect(out.length, 1);
    expect(out.single.exDate, d('2024-05-15'));
    expect(out.single.amount, D('5'));
  });

  test('recorded dividends suppress detection (one-to-one)', () {
    final txs = [buy('X', '2024-02-01', 10, 50), dividendTx('X', '2024-05-20', 10, 0.5)];
    final events = {
      'X': [
        DividendEvent(symbol: 'X', exDate: d('2024-05-15'), amount: 0.5),
        DividendEvent(symbol: 'X', exDate: d('2024-08-15'), amount: 0.5),
      ],
    };
    final out = svc.detect(byPortfolio: {1: txs}, events: events, currencies: {}, now: now);
    expect(out.single.exDate, d('2024-08-15'));
  });

  test('detects unrecorded splits and ignores recorded ones', () {
    final txs = [buy('X', '2024-01-02', 10, 50), splitTx('X', '2024-06-11', 4, 1)];
    final events = {
      'X': [
        SplitEvent(symbol: 'X', date: d('2024-06-10'), numerator: 4, denominator: 1),
        SplitEvent(symbol: 'X', date: d('2024-10-01'), numerator: 2, denominator: 1),
      ],
    };
    final out = svc.detectSplits(byPortfolio: {1: txs}, events: events);
    expect(out.length, 1);
    expect(out.single.event.date, d('2024-10-01'));
  });
}
