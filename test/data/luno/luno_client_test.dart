import 'dart:convert';

import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/luno/luno_client.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:dashfolio/data/net/request_scheduler.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import '../../support/fake_http.dart';
import '../../support/luno_fixtures.dart';

const _creds = LunoCredentials(keyId: 'abcd1234keyid', keySecret: 'SUPERSECRET-value-0123456789');

LunoClient make(FakeAdapter a, {LunoCredentialSource? credentials, int attempts = 3, RequestScheduler? scheduler, Clock? clock}) {
  return LunoClient(
    dio: Dio()..httpClientAdapter = a,
    credentials: credentials ?? () async => _creds,
    maxAttempts: attempts,
    backoff: (_) async {},
    scheduler: scheduler ?? RequestScheduler(name: 'test', clock: clock ?? const SystemClock()),
  );
}

void main() {
  group('requests', () {
    test('balances: HTTPS to api.luno.com with Basic auth built from the credentials', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('balance.json')));
      final accounts = await make(a).balances();
      expect(accounts.map((x) => x.asset), ['MYR', 'XBT', 'ETH']);
      expect(accounts[1].total, Decimal.parse('0.01495'));
      final r = a.requests.single;
      expect(r.uri.scheme, 'https');
      expect(r.uri.host, 'api.luno.com');
      expect(r.uri.path, '/api/1/balance');
      expect(r.method, 'GET');
      expect(r.followRedirects, isFalse);
      expect(r.headers['Authorization'], 'Basic ${base64.encode(utf8.encode('abcd1234keyid:SUPERSECRET-value-0123456789'))}');
    });

    test('ledger rows keep exact decimals even for JSON numbers in exponent form', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('ledger_xbt.json')));
      final rows = await make(a).ledger('1002', minRow: 1, maxRow: 8);
      expect(a.requests.single.queryParameters, {'min_row': '1', 'max_row': '8'});
      expect(rows.length, 7);
      expect(rows[5].kind.name, 'interest');
      expect(rows[5].balanceDelta, Decimal.parse('0.00005'));
      expect(rows[3].txId, 'a1b2c3scrubbed');
      expect(rows[0].tradePair, 'XBTMYR');
      expect(rows[0].tradePrice, Decimal.parse('200000.00'));
      expect(rows.map((r) => r.externalId), ['1002:1', '1002:2', '1002:3', '1002:4', '1002:5', '1002:6', '1002:7']);
    });

    test('ledger fixes the account id from the page when rows omit it, and pending rows without a row index are skipped', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('pending.json')));
      expect(await make(a).pending('1002'), isEmpty);
      expect(a.requests.single.uri.path, '/api/1/accounts/1002/pending');
    });

    test('trades: the order type (not is_buy) gives the user side; since and limit are sent in milliseconds', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('listtrades_xbtmyr.json')));
      final t = await make(a).trades('XBTMYR', since: DateTime.utc(2024, 1, 1));
      expect(t.map((x) => x.isBuy), [true, true, false]);
      expect(t.first.feeCounter, Decimal.parse('2.00'));
      expect(a.requests.single.queryParameters, {'pair': 'XBTMYR', 'since': '1704067200000', 'limit': '1000'});
    });

    test('tickers: one request with repeated pair parameters, and no credentials sent', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('tickers.json')));
      final t = await make(a).tickers(['XBTMYR', 'ETHMYR']);
      expect(t.length, 3);
      expect(a.requests.single.uri.toString(), contains('pair=XBTMYR&pair=ETHMYR'));
      expect(a.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('markets, candles and fee info parse', () async {
      final a = FakeAdapter((o) {
        final name = switch (o.uri.path) {
          '/api/exchange/1/markets' => 'markets.json',
          '/api/exchange/1/candles' => 'candles_1d.json',
          _ => 'fee_info.json',
        };
        return jsonBody(lunoFixtureText(name));
      });
      final c = make(a);
      expect((await c.markets()).map((m) => m.status.name), ['active', 'active', 'postOnly']);
      final candles = await c.candles('XBTMYR', since: DateTime.utc(2024, 5, 30), duration: 86400);
      expect(candles.length, 3);
      expect(candles.last.close, Decimal.parse('300000'));
      expect(a.requests.last.queryParameters, {'pair': 'XBTMYR', 'since': '1717027200000', 'duration': '86400'});
      final fee = await c.feeInfo('XBTMYR');
      expect(fee.takerFeeBuy, Decimal.parse('0.0010'));
    });

    test('identical concurrent GETs share one request', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('balance.json')));
      final c = make(a);
      final results = await Future.wait([c.balances(), c.balances()]);
      expect(results.first.length, results.last.length);
      expect(a.requests.length, 1);
    });
  });

  group('errors', () {
    test('401 / ErrApiKeyRevoked → KeyRevokedFailure without retrying', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('error_revoked.json'), 401));
      await expectLater(make(a).balances(), throwsA(isA<KeyRevokedFailure>()));
      expect(a.requests.length, 1);
    });

    test('ErrInsufficientPerms → ForbiddenFailure', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('error_perms.json'), 403));
      await expectLater(make(a).ledger('1', minRow: 1, maxRow: 2), throwsA(isA<ForbiddenFailure>()));
      expect(a.requests.length, 1);
    });

    test('404 → NotFoundFailure', () async {
      final a = FakeAdapter((o) => jsonBody('{"code":"ErrAccountNotFound","message":"Cannot find that account"}', 404));
      await expectLater(make(a).ledger('9', minRow: 1, maxRow: 2), throwsA(isA<NotFoundFailure>()));
    });

    test('5xx and ErrClusterUnavailable are retried, then fail as NetworkFailure', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('error_unavailable.json'), 503));
      await expectLater(make(a).balances(), throwsA(isA<NetworkFailure>()));
      expect(a.requests.length, 3);
    });

    test('retries a transient failure and then succeeds', () async {
      var n = 0;
      final a = FakeAdapter((o) => ++n < 2 ? jsonBody('oops', 502) : jsonBody(lunoFixtureText('balance.json')));
      expect((await make(a).balances()).length, 3);
      expect(a.requests.length, 2);
    });

    test('429 is retried with Retry-After honoured, then fails as RateLimitedFailure', () async {
      final a = FakeAdapter(
        (o) => jsonBody('{"code":"","message":"slow down"}', 429, {
          'retry-after': ['0'],
        }),
      );
      await expectLater(make(a).balances(), throwsA(isA<RateLimitedFailure>()));
      expect(a.requests.length, 3);
    });

    test('repeated rate limiting opens the circuit, which then fails fast without network calls', () async {
      final clock = FixedClock(DateTime.utc(2024, 1, 1, 12));
      final a = FakeAdapter((o) => jsonBody('{}', 429));
      final c = make(a, attempts: 1, clock: clock);
      await expectLater(c.balances(), throwsA(isA<RateLimitedFailure>()));
      await expectLater(c.tickers(['A']), throwsA(isA<RateLimitedFailure>()));
      expect(c.circuitOpen, isTrue);
      final before = a.requests.length;
      await expectLater(c.markets(), throwsA(isA<RateLimitedFailure>()));
      expect(a.requests.length, before);
    });

    test('a redirect is an error and is never followed', () async {
      final a = FakeAdapter(
        (o) => jsonBody('', 302, {
          'location': ['https://evil.example/steal'],
        }),
      );
      await expectLater(make(a).balances(), throwsA(isA<NetworkFailure>()));
      expect(a.requests.length, 1);
    });

    test('network errors map to NetworkFailure', () async {
      final a = FakeAdapter((o) => throw DioException.connectionError(requestOptions: o, reason: 'offline'));
      await expectLater(make(a).balances(), throwsA(isA<NetworkFailure>()));
    });

    test('missing credentials fail before any request is sent', () async {
      final a = FakeAdapter((o) => jsonBody('{}'));
      final c = make(a, credentials: () async => throw const CredentialsMissingFailure());
      await expectLater(c.balances(), throwsA(isA<CredentialsMissingFailure>()));
      expect(a.requests, isEmpty);
    });

    test('public endpoints do not need credentials', () async {
      final a = FakeAdapter((o) => jsonBody(lunoFixtureText('markets.json')));
      final c = make(a, credentials: () async => throw const CredentialsMissingFailure());
      expect((await c.markets()).length, 3);
    });
  });

  group('secrets', () {
    test('credentials are redacted from toString', () {
      expect('$_creds', isNot(contains('SUPERSECRET')));
      expect('$_creds', isNot(contains('abcd1234')));
      expect(_creds.keyIdHint, 'eyid');
    });

    test('nothing logged while requests succeed or fail contains the key id or secret', () async {
      final records = <String>[];
      Logger.root.level = Level.ALL;
      final sub = Logger.root.onRecord.listen((r) => records.add('${r.message} ${r.error} ${r.stackTrace}'));
      addTearDown(sub.cancel);
      for (final status in [401, 429, 503]) {
        final a = FakeAdapter((o) => jsonBody('{"code":"x","message":"y"}', status));
        await make(a).balances().then((_) {}, onError: (Object _) {});
      }
      final offline = FakeAdapter(
        (o) => throw DioException.connectionError(requestOptions: o, reason: 'abcd1234keyid SUPERSECRET-value-0123456789'),
      );
      await make(offline).balances().then((_) {}, onError: (Object _) {});
      expect(records, isNotEmpty);
      for (final line in records) {
        expect(line, isNot(contains('SUPERSECRET')));
        expect(line, isNot(contains('abcd1234')));
        expect(line, isNot(contains('Basic ')));
      }
    });
  });
}
