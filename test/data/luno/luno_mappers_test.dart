import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/luno/luno_mappers.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/luno_fixtures.dart';

void main() {
  group('decodeLunoJson', () {
    test('quotes only the four ledger number fields, preserving exact digits', () {
      final j = decodeLunoJson('{"balance": 123456789.12345678, "balance_delta":-5e-05,"available":1E+3,"available_delta":0,"other":1.5}');
      expect(j['balance'], '123456789.12345678');
      expect(j['balance_delta'], '-5e-05');
      expect(j['available'], '1E+3');
      expect(j['available_delta'], '0');
      expect(j['other'], 1.5);
    });

    test('leaves string balances and text that merely looks like a field alone', () {
      final j = decodeLunoJson(r'{"balance":"0.10","description":"set \"balance\": 5, ok"}');
      expect(j['balance'], '0.10');
      expect(j['description'], r'set "balance": 5, ok');
    });

    test('exponent and large values reach Decimal exactly', () {
      final rows = LunoMappers.ledger(
        decodeLunoJson(
          '{"id":"1","transactions":[{"row_index":1,"timestamp":1,"currency":"XBT","kind":"TRANSFER","balance_delta":1.2345678901234567e-05,"balance":9007199254740993}]}',
        ),
      );
      expect(rows.single.balanceDelta, Decimal.parse('0.000012345678901234567'));
      expect(rows.single.balance, Decimal.parse('9007199254740993'));
    });

    test('rejects non-object bodies', () {
      expect(() => decodeLunoJson('[1]'), throwsA(isA<ParseFailure>()));
      expect(() => decodeLunoJson('not json'), throwsA(isA<ParseFailure>()));
    });
  });

  group('lunoFailure', () {
    test('maps statuses and codes', () {
      expect(lunoFailure(401, null), isA<KeyRevokedFailure>());
      expect(lunoFailure(400, {'code': 'ErrApiKeyRevoked'}), isA<KeyRevokedFailure>());
      expect(lunoFailure(403, null), isA<ForbiddenFailure>());
      expect(lunoFailure(400, {'code': 'ErrInsufficientPerms'}), isA<ForbiddenFailure>());
      expect(lunoFailure(429, null), isA<RateLimitedFailure>());
      expect(lunoFailure(404, null), isA<NotFoundFailure>());
      expect(lunoFailure(400, {'code': 'ErrOrderNotFound', 'message': 'nope'}).message, 'nope');
      expect(lunoFailure(503, null), isA<NetworkFailure>());
      expect(lunoFailure(400, {'code': 'ErrClusterUnavailable'}), isA<NetworkFailure>());
      expect(lunoFailure(400, {'message': 'bad argument'}).message, 'bad argument');
    });
  });

  group('entities', () {
    test('ledger kinds, market statuses and connection statuses parse with a safe fallback', () {
      expect(LunoLedgerKind.parse('INTEREST'), LunoLedgerKind.interest);
      expect(LunoLedgerKind.parse('SOMETHING_NEW'), LunoLedgerKind.unknown);
      expect(LunoMarketStatus.parse('POSTONLY'), LunoMarketStatus.postOnly);
      expect(LunoMarketStatus.parse('POST_ONLY'), LunoMarketStatus.postOnly);
      expect(LunoMarketStatus.parse(null), LunoMarketStatus.unknown);
      for (final s in LunoConnectionStatus.values) {
        expect(LunoConnectionStatus.parse(s.dbName), s);
      }
    });

    test('symbols map to Luno pairs and Yahoo asset codes', () {
      expect(lunoSymbol('XBTMYR'), 'LUNO:XBTMYR');
      expect(isLunoSymbol('LUNO:XBTMYR'), isTrue);
      expect(isLunoSymbol('BTC-USD'), isFalse);
      expect(lunoPairOf('LUNO:XBTMYR'), 'XBTMYR');
      expect(yahooAssetCode('XBT'), 'BTC');
      expect(yahooAssetCode('ETH'), 'ETH');
      expect(lunoAssetName('XBT'), 'Bitcoin');
      expect(lunoAssetName('ZZZ'), 'ZZZ');
      expect(isLunoFiat('MYR'), isTrue);
      expect(isLunoFiat('XBT'), isFalse);
    });

    test('a cursor matches an account only when all three balances are identical', () {
      final acct = LunoMappers.balances(lunoFixture('balance.json'))[1];
      LunoAccountCursor cursor({String? reserved}) => LunoAccountCursor(
        connectionId: 1,
        accountId: acct.accountId,
        asset: 'XBT',
        balanceSnapshot: Decimal.parse('0.01395'),
        reservedSnapshot: Decimal.parse(reserved ?? '0.001'),
        unconfirmedSnapshot: Decimal.zero,
      );
      expect(cursor().matches(acct), isTrue);
      expect(cursor(reserved: '0.002').matches(acct), isFalse);
    });
  });

  test('fee info falls back to the deprecated single maker/taker fee', () {
    final f = lunoFeeInfo({'maker_fee': '0.001', 'taker_fee': '0.002', 'thirty_day_volume': '5'});
    expect((f.makerFeeBuy, f.takerFeeSell), (Decimal.parse('0.001'), Decimal.parse('0.002')));
  });

  test('transfers keep positive amounts and the on-chain id', () {
    final t = LunoMappers.transfers(lunoFixture('transfers_xbt.json'));
    expect(t.map((x) => x.inbound), [true, false]);
    expect(t.last.fee, Decimal.parse('0.0001'));
    expect(t.last.transactionId, 'a1b2c3scrubbed');
  });
}
