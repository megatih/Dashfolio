import 'package:dashfolio/core/decimal_ext.dart';
import 'package:dashfolio/data/luno/luno_mappers.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:dashfolio/domain/entities/portfolio.dart';
import 'package:dashfolio/domain/services/holdings_engine.dart';
import 'package:dashfolio/domain/services/luno_ledger_mapper.dart';
import 'package:dashfolio/domain/services/luno_reconciliation.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/luno_fixtures.dart';

final _now = DateTime.utc(2024, 6, 1, 12);

/// Within a few billionths: prices are rounded to 12 decimals.
Matcher closeTo2(Decimal expected) =>
    predicate<Decimal>((v) => (v - expected).abs() < Decimal.parse('0.000001'), 'within 1e-6 of $expected');

Decimal? _price(String asset, DateTime at) => switch (asset) {
  'XBT' => Decimal.parse('260000'),
  'ETH' => Decimal.parse('8000'),
  _ => null,
};

LunoMapContext ctx({FiatPrice? priceOf, FxToBase? fx, String home = 'MYR', DateTime? now}) => LunoMapContext(
  portfolioId: 5,
  connectionId: 9,
  homeFiat: home,
  now: now ?? _now,
  priceOf: priceOf ?? _price,
  fxToBase: fx ?? (c, _) => Decimal.one,
);

int _rowSeq = 0;

LunoLedgerEntry row(
  String account,
  String asset,
  LunoLedgerKind kind,
  Object delta, {
  String ref = '',
  String at = '2024-02-01T10:00:00Z',
  String? pair,
  int? seq,
  String? txId,
  int? index,
}) => LunoLedgerEntry(
  accountId: account,
  rowIndex: index ?? ++_rowSeq,
  timestamp: DateTime.parse(at),
  asset: asset,
  kind: kind,
  balanceDelta: dec(delta),
  reference: ref,
  tradePair: pair,
  tradeSequence: seq,
  txId: txId,
);

List<LunoLedgerEntry> fixtureRows() => [
  for (final f in ['ledger_myr.json', 'ledger_xbt.json', 'ledger_eth.json']) ...LunoMappers.ledger(lunoFixture(f)),
];

PortfolioTransaction byType(LunoMapResult r, TxType t) => r.transactions.singleWhere((x) => x.type == t);

void main() {
  group('the fixture account', () {
    final r = const LunoLedgerMapper().map(fixtureRows(), ctx());

    test('every ledger row is understood and nothing is held back', () {
      expect(r.mapped.length, 15);
      expect(r.unrecognised, isEmpty);
      expect(r.deferred, isEmpty);
      expect(r.warnings, isEmpty);
      expect(r.transactions.length, 9);
      expect(r.transactions.every((t) => t.source == TxSource.luno && t.connectionId == 9 && t.portfolioId == 5), isTrue);
      expect(r.transactions.map((t) => t.externalId).toSet().length, 9, reason: 'external ids are unique');
    });

    test('a fiat buy pairs both legs, takes the price from the ledger and attaches the fee row', () {
      final buy1 = r.transactions.firstWhere((t) => t.externalId == '1001:2+1002:1');
      expect(buy1.type, TxType.buy);
      expect(buy1.symbol, 'LUNO:XBTMYR');
      expect((buy1.quantity, buy1.price, buy1.fees, buy1.currency), (D('0.005'), D('200000'), D('2'), 'MYR'));
      expect(buy1.tradeDate, DateTime.utc(2024, 1, 15));
      expect(buy1.executedAt, DateTime.utc(2024, 1, 15, 3));
      final sell = r.transactions.singleWhere((t) => t.type == TxType.sell);
      expect((sell.quantity, sell.price, sell.fees), (D('0.004'), D('225000'), D('0')));
    });

    test('fiat transfers, on-chain sends with their network fee, interest and receives', () {
      final dep = r.transactions.singleWhere((t) => t.type == TxType.deposit);
      expect((dep.symbol, dep.quantity, dep.price, dep.currency), (null, D('1'), D('5000'), 'MYR'));
      expect(byType(r, TxType.withdrawal).price, D('1000'));

      final out = byType(r, TxType.transferOut);
      expect((out.symbol, out.quantity, out.fees), ('LUNO:XBTMYR', D('0.002'), D('0.0001')));
      expect(out.notes, contains('a1b2c3scrubbed'));
      final reward = byType(r, TxType.reward);
      expect((reward.quantity, reward.price, reward.currency), (D('0.00005'), D('260000'), 'MYR'));
      final inn = byType(r, TxType.transferIn);
      expect((inn.quantity, inn.price), (D('0.01'), D('260000')));
      // The network-fee row was consumed by the send; it must not also book a standalone fee.
      expect(r.transactions.where((t) => t.type == TxType.fee), isEmpty);
    });

    test('replayed, the transactions equal the balances Luno reports', () {
      for (final method in CostMethod.values) {
        final pos = const HoldingsEngine().replay(r.transactions, method);
        final accounts = LunoMappers.balances(lunoFixture('balance.json'));
        final held = {for (final p in pos.positions.values) p.symbol: p.quantity};
        expect(
          reconcileLuno(accounts: accounts, heldBySymbol: held),
          isEmpty,
          reason: '$method: $held',
        );
        expect(pos.cashBase, D('1598'), reason: 'MYR wallet balance');
        expect(pos.warnings, isEmpty);
      }
    });

    test('mapping is deterministic and independent of input order', () {
      final shuffled = fixtureRows().reversed.toList();
      final again = const LunoLedgerMapper().map(shuffled, ctx());
      expect(again.transactions.map((t) => t.externalId).toList(), r.transactions.map((t) => t.externalId).toList());
    });
  });

  group('trades', () {
    test('crypto for crypto becomes a sell and a buy valued in the home fiat', () {
      final r = const LunoLedgerMapper().map([
        row('A', 'ETH', LunoLedgerKind.exchange, 1, ref: 'S', pair: 'ETHXBT', seq: 1),
        row('B', 'XBT', LunoLedgerKind.exchange, -0.03, ref: 'S', pair: 'ETHXBT', seq: 1),
      ], ctx());
      expect(r.transactions.length, 2);
      final buy = byType(r, TxType.buy);
      final sell = byType(r, TxType.sell);
      // 0.03 XBT at 260000 = 7800 MYR for 1 ETH.
      expect((buy.symbol, buy.quantity, buy.price, buy.currency), ('LUNO:ETHMYR', D('1'), D('7800'), 'MYR'));
      expect((sell.symbol, sell.quantity, sell.price), ('LUNO:XBTMYR', D('0.03'), D('260000')));
      expect(r.transactions.map((t) => t.externalId).toSet().length, 2);
    });

    test('a crypto swap with no fiat price is held back with a warning rather than booked at zero', () {
      final r = const LunoLedgerMapper().map([
        row('A', 'ETH', LunoLedgerKind.exchange, 1, ref: 'S', pair: 'ETHXBT', seq: 1),
        row('B', 'XBT', LunoLedgerKind.exchange, -0.03, ref: 'S', pair: 'ETHXBT', seq: 1),
      ], ctx(priceOf: (_, _) => null));
      expect(r.transactions, isEmpty);
      expect(r.deferred.length, 2);
      expect(r.warnings.single, contains('No MYR price'));
    });

    test('a trade paid in another fiat is expressed in the home fiat at that day\'s rate, in the same position as everything else', () {
      final usdBase = ctx(fx: (c, _) => c == 'USD' ? Decimal.parse('4.5') : Decimal.one);
      final entries = [
        row('U', 'USD', LunoLedgerKind.exchange, -500, ref: 'T', pair: 'XBTUSD', seq: 1, at: '2024-02-01T10:00:00Z'),
        row('X', 'XBT', LunoLedgerKind.exchange, 0.01, ref: 'T', pair: 'XBTUSD', seq: 1, at: '2024-02-01T10:00:00Z'),
        row('U', 'USD', LunoLedgerKind.fee, -2, ref: 'T', at: '2024-02-01T10:00:00Z'),
        row('X', 'XBT', LunoLedgerKind.transfer, -0.004, ref: 'O', at: '2024-03-01T10:00:00Z'),
      ];
      final r = const LunoLedgerMapper().map(entries, usdBase);
      final buy = byType(r, TxType.buy);
      expect(
        (buy.symbol, buy.currency, buy.quantity, buy.price, buy.fees, buy.notes),
        ('LUNO:XBTMYR', 'MYR', D('0.01'), D('225000'), D('9'), 'Paid in USD'),
      );
      expect(byType(r, TxType.transferOut).symbol, 'LUNO:XBTMYR', reason: 'the send draws down the position the USD trade created');
      final pos = const HoldingsEngine().replay(r.transactions, CostMethod.average);
      expect(pos.positions.keys, ['LUNO:XBTMYR']);
      expect(pos.positions['LUNO:XBTMYR']!.quantity, D('0.006'));
      expect(pos.warnings, isEmpty);
    });

    test('several fills of one order (same reference, different sequence) become separate trades', () {
      final r = const LunoLedgerMapper().map([
        row('F', 'MYR', LunoLedgerKind.exchange, -100, ref: 'O', pair: 'XBTMYR', seq: 1),
        row('F', 'MYR', LunoLedgerKind.exchange, -200, ref: 'O', pair: 'XBTMYR', seq: 2),
        row('X', 'XBT', LunoLedgerKind.exchange, 0.001, ref: 'O', pair: 'XBTMYR', seq: 1),
        row('X', 'XBT', LunoLedgerKind.exchange, 0.002, ref: 'O', pair: 'XBTMYR', seq: 2),
      ], ctx());
      expect(r.transactions.map((t) => (t.quantity, t.price)).toSet(), {(D('0.001'), D('100000')), (D('0.002'), D('100000'))});
    });

    test('a leg whose counterpart has not arrived is deferred while recent, unrecognised once old', () {
      final recent = row('A', 'XBT', LunoLedgerKind.exchange, 1, ref: 'R', at: '2024-06-01T11:55:00Z', pair: 'XBTMYR', seq: 1);
      final old = row('A', 'XBT', LunoLedgerKind.exchange, 1, ref: 'Q', at: '2024-05-01T11:55:00Z', pair: 'XBTMYR', seq: 1);
      final r = const LunoLedgerMapper().map([recent, old], ctx());
      expect(r.deferred, {recent.externalId});
      expect(r.unrecognised.keys, [old.externalId]);
      expect(r.transactions, isEmpty);
    });

    test('malformed trades are reported, not guessed', () {
      final sameSign = const LunoLedgerMapper().map([
        row('A', 'XBT', LunoLedgerKind.exchange, 1, ref: 'S', pair: 'XBTMYR', seq: 1),
        row('B', 'MYR', LunoLedgerKind.exchange, 5, ref: 'S', pair: 'XBTMYR', seq: 1),
      ], ctx());
      expect(sameSign.unrecognised.length, 2);
      final wrongPair = const LunoLedgerMapper().map([
        row('A', 'XBT', LunoLedgerKind.exchange, 1, ref: 'S', pair: 'ETHZAR', seq: 1),
        row('B', 'ETH', LunoLedgerKind.exchange, -5, ref: 'S', pair: 'ETHZAR', seq: 1),
      ], ctx());
      expect(wrongPair.unrecognised.length, 2);
      final threeRows = const LunoLedgerMapper().map([
        row('A', 'XBT', LunoLedgerKind.exchange, 1, ref: 'S', seq: 1),
        row('B', 'MYR', LunoLedgerKind.exchange, -5, ref: 'S', seq: 1),
        row('C', 'MYR', LunoLedgerKind.exchange, -5, ref: 'S', seq: 1),
      ], ctx());
      expect(threeRows.unrecognised.length, 3);
    });

    test('without a pair the single fiat leg is the counter', () {
      final r = const LunoLedgerMapper().map([
        row('A', 'XBT', LunoLedgerKind.exchange, -0.5, ref: 'S'),
        row('B', 'MYR', LunoLedgerKind.exchange, 100, ref: 'S'),
      ], ctx());
      expect(byType(r, TxType.sell).price, D('200'));
    });

    test('a fee in the received coin is folded into a buy: fewer coins for the same money, no stray fee transaction', () {
      final r = const LunoLedgerMapper().map([
        row('A', 'XBT', LunoLedgerKind.exchange, 0.01, ref: 'S', pair: 'XBTMYR', seq: 1),
        row('B', 'MYR', LunoLedgerKind.exchange, -2000, ref: 'S', pair: 'XBTMYR', seq: 1),
        row('A', 'XBT', LunoLedgerKind.fee, -0.00002, ref: 'S'),
      ], ctx());
      expect(r.transactions.map((t) => t.type), [TxType.buy]);
      final buy = r.transactions.single;
      expect((buy.quantity, buy.fees), (D('0.00998'), D('0')));
      expect(buy.price * buy.quantity, closeTo2(D('2000')), reason: 'all the money is accounted for');
      expect(buy.notes, 'Includes fee of 0.00002 XBT');
      final pos = const HoldingsEngine().replay(r.transactions, CostMethod.average).positions['LUNO:XBTMYR']!;
      expect((pos.quantity, pos.realizedBase), (D('0.00998'), D('0')));
    });

    test('a fee in the sold coin is charged on top of the sale: more coins leave, for the same proceeds', () {
      final r = const LunoLedgerMapper().map([
        row('A', 'XBT', LunoLedgerKind.exchange, 0.02, ref: 'B', pair: 'XBTMYR', seq: 1, at: '2024-01-01T10:00:00Z'),
        row('B', 'MYR', LunoLedgerKind.exchange, -4000, ref: 'B', pair: 'XBTMYR', seq: 1, at: '2024-01-01T10:00:00Z'),
        row('A', 'XBT', LunoLedgerKind.exchange, -0.01, ref: 'S', pair: 'XBTMYR', seq: 2, at: '2024-02-01T10:00:00Z'),
        row('B', 'MYR', LunoLedgerKind.exchange, 3000, ref: 'S', pair: 'XBTMYR', seq: 2, at: '2024-02-01T10:00:00Z'),
        row('A', 'XBT', LunoLedgerKind.fee, -0.00004, ref: 'S', at: '2024-02-01T10:00:00Z'),
      ], ctx());
      final sell = byType(r, TxType.sell);
      expect(sell.quantity, D('0.01004'));
      expect(sell.quantity * sell.price, closeTo2(D('3000')));
      final pos = const HoldingsEngine().replay(r.transactions, CostMethod.average).positions['LUNO:XBTMYR']!;
      expect(pos.quantity, D('0.00996'), reason: '0.02 bought, 0.01 sold plus its 0.00004 fee: exactly what the balance would show');
      expect(r.transactions.where((t) => t.type == TxType.fee), isEmpty);
    });

    test('a fee in the traded coin that is not part of the trade (different reference) is still its own fee', () {
      final r = const LunoLedgerMapper().map([
        row('A', 'XBT', LunoLedgerKind.exchange, 0.01, ref: 'S', pair: 'XBTMYR', seq: 1),
        row('B', 'MYR', LunoLedgerKind.exchange, -2000, ref: 'S', pair: 'XBTMYR', seq: 1),
        row('A', 'XBT', LunoLedgerKind.fee, -0.00002, ref: 'OTHER'),
      ], ctx());
      expect(r.transactions.map((t) => t.type).toSet(), {TxType.buy, TxType.fee});
    });

    test('reserve/release rows (no kind, no balance change) are silently ignored, not reported', () {
      final reserve = row('M', 'MYR', LunoLedgerKind.unknown, 0, ref: 'R', at: '2024-01-01T10:00:00Z');
      final r = const LunoLedgerMapper().map([reserve], ctx());
      expect(r.transactions, isEmpty);
      expect(r.unrecognised, isEmpty);
      expect(r.deferred, isEmpty);
      expect(r.mapped, {reserve.externalId}, reason: 'handled, so it does not come back on every sync');
      // But an unknown row that does move the balance is still reported.
      final odd = row('M', 'MYR', LunoLedgerKind.unknown, 5, ref: 'R2');
      expect(const LunoLedgerMapper().map([odd], ctx()).unrecognised.keys, [odd.externalId]);
    });
  });

  group('transfers, interest and fees', () {
    test('a receive needs a fiat price and is held back until one exists', () {
      final e = row('A', 'XBT', LunoLedgerKind.transfer, 0.1, ref: 'T');
      final none = const LunoLedgerMapper().map([e], ctx(priceOf: (_, _) => null));
      expect(none.deferred, {e.externalId});
      expect(none.warnings.single, contains('XBT'));
      final later = const LunoLedgerMapper().map([e], ctx());
      expect(later.transactions.single.type, TxType.transferIn);
    });

    test('a send does not need a price', () {
      final r = const LunoLedgerMapper().map([row('A', 'XBT', LunoLedgerKind.transfer, -0.1, ref: 'T')], ctx(priceOf: (_, _) => null));
      expect((r.transactions.single.type, r.transactions.single.price), (TxType.transferOut, D('0')));
    });

    test('fiat movements in a currency other than the base use that currency and its FX rate', () {
      final r = const LunoLedgerMapper().map([
        row('U', 'USD', LunoLedgerKind.transfer, 250, ref: 'D'),
      ], ctx(fx: (c, _) => c == 'USD' ? Decimal.parse('4.5') : Decimal.one));
      final dep = r.transactions.single;
      expect((dep.currency, dep.fxRateToBase), ('USD', D('4.5')));
    });

    test('fiat interest is a deposit; crypto interest is a reward; non-positive interest is reported', () {
      final r = const LunoLedgerMapper().map([
        row('A', 'MYR', LunoLedgerKind.interest, 1.5),
        row('B', 'XBT', LunoLedgerKind.interest, 0.0001),
        row('B', 'XBT', LunoLedgerKind.interest, -0.0001),
      ], ctx());
      expect(r.transactions.map((t) => t.type).toSet(), {TxType.deposit, TxType.reward});
      expect(r.unrecognised.length, 1);
    });

    test('standalone fees: fiat is a cash outflow, crypto reduces the holding, a refund is reported', () {
      final r = const LunoLedgerMapper().map([
        row('A', 'MYR', LunoLedgerKind.fee, -3),
        row('B', 'XBT', LunoLedgerKind.fee, -0.00001),
        row('A', 'MYR', LunoLedgerKind.fee, 2),
      ], ctx());
      final fiat = r.transactions.firstWhere((t) => t.symbol == null);
      expect((fiat.type, fiat.price), (TxType.fee, D('3')));
      expect(r.transactions.firstWhere((t) => t.symbol != null).symbol, 'LUNO:XBTMYR');
      expect(r.unrecognised.length, 1);
    });

    test('unknown ledger kinds are reported with a reason and never booked', () {
      final e = row('A', 'MYR', LunoLedgerKind.unknown, 10);
      final r = const LunoLedgerMapper().map([e], ctx());
      expect(r.transactions, isEmpty);
      expect(r.unrecognised[e.externalId], isNotEmpty);
    });

    test('zero-amount transfers are reported', () {
      expect(const LunoLedgerMapper().map([row('A', 'XBT', LunoLedgerKind.transfer, 0)], ctx()).unrecognised.length, 1);
    });
  });

  group('reconciliation', () {
    final accounts = LunoMappers.balances(lunoFixture('balance.json'));

    test('reports the delta for every asset that differs, and ignores fiat wallets and unconfirmed amounts', () {
      final held = {'LUNO:XBTMYR': D('0.01'), 'LUNO:ETHMYR': D('0.1'), 'LUNO:DOGEMYR': D('5')};
      final mismatches = reconcileLuno(accounts: accounts, heldBySymbol: held);
      expect(mismatches.map((m) => m.asset), ['DOGE', 'XBT']);
      final xbt = mismatches.last;
      expect((xbt.expected, xbt.actual, xbt.delta), (D('0.01495'), D('0.01'), D('-0.00495')));
      expect('$xbt', contains('XBT'));
    });

    test('quantities in several fiat-quoted symbols of one asset add up', () {
      final held = {'LUNO:XBTMYR': D('0.01'), 'LUNO:XBTUSD': D('0.00495'), 'LUNO:ETHMYR': D('0.1')};
      expect(reconcileLuno(accounts: accounts, heldBySymbol: held), isEmpty);
    });

    test('lunoSymbolAsset', () {
      expect(lunoSymbolAsset('LUNO:XBTMYR'), 'XBT');
      expect(lunoSymbolAsset('AAPL'), isNull);
      expect(lunoSymbolAsset('LUNO:MYR'), isNull);
    });
  });
}
