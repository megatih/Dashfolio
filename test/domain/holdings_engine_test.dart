import 'package:decimal/decimal.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashfolio/domain/services/holdings_engine.dart';

import '../support/builders.dart';

void main() {
  const engine = HoldingsEngine();

  group('average cost', () {
    test('weighted average across buys, fees capitalised', () {
      final r = engine.replay([buy('AAPL', '2024-01-02', 10, 100, fees: 10), buy('AAPL', '2024-02-01', 10, 200)], CostMethod.average);
      final p = r.positions['AAPL']!;
      expect(p.quantity, D('20'));
      expect(p.costLocal, D('3010'));
      expect(p.avgCostLocal, D('150.5'));
      expect(p.lots.length, 1);
    });

    test('partial sell realises P&L against average cost', () {
      final r = engine.replay([
        buy('AAPL', '2024-01-02', 10, 100),
        buy('AAPL', '2024-02-01', 10, 200),
        sell('AAPL', '2024-03-01', 5, 220, fees: 5),
      ], CostMethod.average);
      final p = r.positions['AAPL']!;
      expect(p.quantity, D('15'));
      // avg 150; proceeds 5*220-5 = 1095; cost removed 750 -> 345
      expect(p.realizedBase, D('345'));
      expect(p.costBase, D('2250'));
    });

    test('full sell closes the position and clears lots', () {
      final r = engine.replay([buy('X', '2024-01-02', 4, 10), sell('X', '2024-01-05', 4, 12)], CostMethod.average);
      final p = r.positions['X']!;
      expect(p.isOpen, isFalse);
      expect(p.lots, isEmpty);
      expect(p.realizedBase, D('8'));
      expect(r.open, isEmpty);
    });
  });

  group('FIFO', () {
    test('sell consumes oldest lot first', () {
      final r = engine.replay([
        buy('AAPL', '2024-01-02', 10, 100),
        buy('AAPL', '2024-02-01', 10, 200),
        sell('AAPL', '2024-03-01', 15, 250),
      ], CostMethod.fifo);
      final p = r.positions['AAPL']!;
      // cost removed: 10*100 + 5*200 = 2000 ; proceeds 3750
      expect(p.realizedBase, D('1750'));
      expect(p.quantity, D('5'));
      expect(p.lots.length, 1);
      expect(p.costLocal, D('1000'));
    });

    test('differs from average for the same trades', () {
      final txs = [buy('A', '2024-01-02', 10, 100), buy('A', '2024-02-01', 10, 200), sell('A', '2024-03-01', 10, 250)];
      final fifo = engine.replay(txs, CostMethod.fifo).positions['A']!.realizedBase;
      final avg = engine.replay(txs, CostMethod.average).positions['A']!.realizedBase;
      expect(fifo, D('1500'));
      expect(avg, D('1000'));
    });
  });

  group('splits', () {
    test('quantity scales and total cost is preserved', () {
      final r = engine.replay([buy('NVDA', '2024-01-02', 10, 1000), splitTx('NVDA', '2024-06-10', 10, 1)], CostMethod.average);
      final p = r.positions['NVDA']!;
      expect(p.quantity, D('100'));
      expect(p.costLocal, D('10000'));
      expect(p.avgCostLocal, D('100'));
    });

    test('reverse split', () {
      final r = engine.replay([buy('X', '2024-01-02', 100, 1), splitTx('X', '2024-02-01', 1, 10)], CostMethod.fifo);
      expect(r.positions['X']!.quantity, D('10'));
      expect(r.positions['X']!.avgCostLocal, D('10'));
    });
  });

  group('multi-currency', () {
    test('cost and realized are tracked in base via per-transaction FX', () {
      final r = engine.replay([
        buy('SAP.DE', '2024-01-02', 10, 100, currency: 'EUR', fx: '1.10'),
        sell('SAP.DE', '2024-02-01', 10, 120, currency: 'EUR', fx: '1.20'),
      ], CostMethod.average);
      final p = r.positions['SAP.DE']!;
      // cost 1000 EUR * 1.10 = 1100 USD ; proceeds 1200 EUR * 1.20 = 1440 USD
      expect(p.realizedBase, D('340'));
    });
  });

  group('edge cases', () {
    test('oversell is clamped and flagged, not thrown', () {
      final r = engine.replay([buy('X', '2024-01-02', 5, 10), sell('X', '2024-01-03', 8, 12)], CostMethod.average);
      expect(r.positions['X']!.quantity, Decimal.zero);
      expect(r.warnings, isNotEmpty);
      // only 5 shares sold: proceeds 5*12 = 60, cost 50
      expect(r.positions['X']!.realizedBase, D('10'));
    });

    test('same-day buy is processed before sell', () {
      final r = engine.replay([sell('X', '2024-01-03', 5, 12), buy('X', '2024-01-03', 5, 10)], CostMethod.average);
      expect(r.warnings, isEmpty);
      expect(r.positions['X']!.quantity, Decimal.zero);
    });

    test('opening position behaves like a buy without cash impact', () {
      final r = engine.replay([tx(TxType.openingPosition, 'X', '2024-01-02', quantity: 10, price: 50)], CostMethod.average);
      expect(r.positions['X']!.quantity, D('10'));
      expect(r.cashBase, Decimal.zero);
    });

    test('dividends accumulate and asOf cuts off later transactions', () {
      final txs = [buy('X', '2024-01-02', 10, 50), dividendTx('X', '2024-03-01', 10, 0.5), dividendTx('X', '2024-06-01', 10, 0.5)];
      expect(engine.replay(txs, CostMethod.average).positions['X']!.dividendsBase, D('10'));
      expect(engine.replay(txs, CostMethod.average, asOf: DateTime.utc(2024, 4, 1)).positions['X']!.dividendsBase, D('5'));
    });

    test('cash is derived from deposits, trades, dividends and fees', () {
      final txs = [
        tx(TxType.deposit, null, '2024-01-01', quantity: 1, price: 1000),
        buy('X', '2024-01-02', 5, 100),
        sell('X', '2024-01-10', 2, 120),
        tx(TxType.withdrawal, null, '2024-01-11', quantity: 1, price: 100),
        tx(TxType.fee, null, '2024-01-12', quantity: 1, price: 5),
      ];
      final r = engine.replay(txs, CostMethod.average);
      expect(r.hasCashActivity, isTrue);
      expect(r.cashBase, D('1000') - D('500') + D('240') - D('100') - D('5'));
    });
  });

  group('v2 transaction types (Luno)', () {
    test('transfer_in adds a lot at market value, with no cash flow', () {
      final r = engine.replay([
        tx(TxType.transferIn, 'LUNO:XBTMYR', '2024-01-02', quantity: 2, price: 100, currency: 'MYR'),
      ], CostMethod.average);
      final p = r.positions['LUNO:XBTMYR']!;
      expect(p.quantity, D('2'));
      expect(p.costLocal, D('200'));
      expect(r.cashBase, D('0'));
      expect(r.hasCashActivity, isFalse);
    });

    test('transfer_out removes quantity at cost with no realized P&L; the fee is a realized loss', () {
      final r = engine.replay([
        buy('X', '2024-01-02', 10, 100),
        tx(TxType.transferOut, 'X', '2024-01-05', quantity: 4, price: 150, fees: 1),
      ], CostMethod.average);
      final p = r.positions['X']!;
      expect(p.quantity, D('5'));
      expect(p.costBase, D('500'));
      expect(p.realizedBase, D('-100'));
    });

    test('transfer_out beyond holdings clamps and warns', () {
      final r = engine.replay([buy('X', '2024-01-02', 1, 100), tx(TxType.transferOut, 'X', '2024-01-05', quantity: 3)], CostMethod.fifo);
      expect(r.positions['X']!.quantity, D('0'));
      expect(r.warnings, isNotEmpty);
    });

    test('reward adds quantity at value-at-receipt and counts as income without inflating unrealized P&L', () {
      final r = engine.replay([tx(TxType.reward, 'X', '2024-01-02', quantity: 0.5, price: 200, fx: 2)], CostMethod.average);
      final p = r.positions['X']!;
      expect(p.quantity, D('0.5'));
      expect(p.costBase, D('200'));
      expect(p.dividendsBase, D('200'));
      expect(r.cashBase, D('0'));
    });

    test('a fee with a symbol reduces quantity and is a realized loss; without a symbol it is a cash outflow', () {
      final r = engine.replay([
        buy('X', '2024-01-02', 10, 10),
        tx(TxType.fee, 'X', '2024-01-03', quantity: 1, price: 10),
        tx(TxType.fee, null, '2024-01-04', quantity: 1, price: 3),
      ], CostMethod.average);
      final p = r.positions['X']!;
      expect(p.quantity, D('9'));
      expect(p.realizedBase, D('-10'));
      expect(r.cashBase, D('-103'));
    });

    test('rows with an execution time order by it within a day, after rows without one', () {
      final t0 = DateTime.utc(2024, 1, 2, 9);
      final r = engine.replay([
        // Sell executed before the buy on the same day must not be reordered by rank.
        tx(TxType.sell, 'X', '2024-01-02', quantity: 1, price: 12, executedAt: t0),
        tx(TxType.buy, 'X', '2024-01-02', quantity: 1, price: 10, executedAt: t0.subtract(const Duration(hours: 1))),
      ], CostMethod.average);
      final p = r.positions['X']!;
      expect(r.warnings, isEmpty);
      expect(p.realizedBase, D('2'));
    });
  });
}
