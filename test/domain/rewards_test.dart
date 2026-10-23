import 'package:dashfolio/core/decimal_ext.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/services/rewards.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

void main() {
  const svc = RewardService();
  final now = DateTime.utc(2024, 6, 15);

  final txs = [
    tx(TxType.reward, 'LUNO:XBTMYR', '2024-06-02', quantity: '0.001', price: 260000, currency: 'MYR', fx: '0.2'), // 52 base
    tx(TxType.reward, 'LUNO:XBTMYR', '2024-04-10', quantity: '0.002', price: 250000, currency: 'MYR', fx: '0.2'), // 100 base
    tx(TxType.reward, 'LUNO:ETHMYR', '2024-04-20', quantity: '0.1', price: 10000, currency: 'MYR', fx: '0.2'), // 200 base
    tx(TxType.reward, 'LUNO:XBTMYR', '2022-01-10', quantity: '1', price: 100, currency: 'MYR'), // all-time only
    tx(TxType.dividend, 'AAPL', '2024-06-03', quantity: 10, price: 1), // not a reward
    tx(TxType.buy, 'LUNO:XBTMYR', '2024-06-04', quantity: 1, price: 1), // not a reward
  ];

  test('monthly buckets the last twelve months in base currency and ignores other types', () {
    final m = svc.monthly(txs, now);
    expect(m.length, 12);
    expect(m.first.month, DateTime.utc(2023, 7, 1));
    expect(m.last.month, DateTime.utc(2024, 6, 1));
    expect(m.last.amountBase, D('52'));
    expect(m.firstWhere((x) => x.month == DateTime.utc(2024, 4, 1)).amountBase, D('300'));
    expect(m.fold(dec(0), (s, x) => s + x.amountBase), D('352'), reason: 'the 2022 reward is outside the window');
  });

  test('by asset sums value, largest first, optionally since a date', () {
    final all = svc.byAsset(txs);
    expect(all.map((x) => x.symbol), ['LUNO:XBTMYR', 'LUNO:ETHMYR']);
    expect((all.first.amountBase, all.last.amountBase), (D('252'), D('200')));
    final recent = svc.byAsset(txs, since: DateTime.utc(2023, 6, 15));
    expect(recent.map((x) => x.symbol), ['LUNO:ETHMYR', 'LUNO:XBTMYR'], reason: 'the 2022 reward no longer counts');
    expect((recent.first.amountBase, recent.last.amountBase), (D('200'), D('152')));
  });

  test('totals', () {
    expect(svc.totalReceived(txs), D('452'));
    expect(svc.totalReceived(txs, since: DateTime.utc(2023, 6, 15)), D('352'));
    expect(svc.totalReceived(const []), D('0'));
  });
}
