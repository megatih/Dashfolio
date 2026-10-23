import 'dart:async';
import 'dart:typed_data';

import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/yahoo/crumb_manager.dart';
import 'package:dashfolio/data/yahoo/yahoo_client.dart';
import 'package:dashfolio/data/yahoo/yahoo_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

typedef Handler = ResponseBody Function(RequestOptions o);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  Handler handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody body(String text, int status) => ResponseBody.fromString(
  text,
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

YahooClient make(FakeAdapter a, {YahooConfig config = const YahooConfig(), Clock? clock, CrumbManager? crumb, int attempts = 3}) {
  final dio = Dio()..httpClientAdapter = a;
  return YahooClient(
    dio: dio,
    config: config,
    crumbManager: crumb,
    maxAttempts: attempts,
    backoff: (_) async {},
    clock: clock ?? const SystemClock(),
  );
}

void main() {
  test('returns decoded JSON on 200 and de-duplicates identical in-flight calls', () async {
    final a = FakeAdapter((o) => body(fixtureText('chart_equity.json'), 200));
    final c = make(a);
    final results = await Future.wait([c.chart('AAPL', range: '1mo'), c.chart('AAPL', range: '1mo')]);
    expect(results.first['chart'], isNotNull);
    expect(a.requests.length, 1);
    expect(a.requests.single.uri.path, '/v8/finance/chart/AAPL');
    expect(a.requests.single.queryParameters['range'], '1mo');
    expect(a.requests.single.headers['User-Agent'], contains('Mozilla'));
  });

  test('retries on 5xx and alternates hosts, then succeeds', () async {
    var n = 0;
    final a = FakeAdapter((o) => ++n < 3 ? body('oops', 503) : body(fixtureText('search.json'), 200));
    final c = make(a);
    final r = await c.search('apple');
    expect(r['quotes'], isNotNull);
    expect(a.requests.length, 3);
    expect(a.requests.map((r) => r.uri.host).toSet(), {'query1.finance.yahoo.com', 'query2.finance.yahoo.com'});
  });

  test('gives up after max attempts with a rate-limit failure on 429', () async {
    final a = FakeAdapter((o) => body('Too Many Requests', 429));
    final c = make(a);
    await expectLater(c.search('x'), throwsA(isA<RateLimitedFailure>()));
    expect(a.requests.length, 3);
  });

  test('circuit opens after repeated rate limiting and fails fast, closing after the window', () async {
    final clock = FixedClock(DateTime.utc(2024, 1, 1, 12));
    final a = FakeAdapter((o) => body('Too Many Requests', 429));
    final c = make(a, clock: clock, attempts: 1);
    await expectLater(c.search('a'), throwsA(isA<RateLimitedFailure>()));
    await expectLater(c.search('b'), throwsA(isA<RateLimitedFailure>()));
    expect(c.circuitOpen, isTrue);
    final before = a.requests.length;
    await expectLater(c.search('c'), throwsA(isA<RateLimitedFailure>()));
    expect(a.requests.length, before); // failed fast, no network
    clock.value = clock.value.add(const Duration(seconds: 61));
    expect(c.circuitOpen, isFalse);
  });

  test('404 with a JSON error payload is returned for the mapper to translate', () async {
    final a = FakeAdapter((o) => body(fixtureText('chart_error.json'), 404));
    final r = await make(a).chart('ZZZ', range: '1mo');
    expect((r['chart']! as Map)['error'], isNotNull);
  });

  test('404 without JSON becomes NotFoundFailure', () async {
    final a = FakeAdapter((o) => body('Not Found', 404));
    await expectLater(make(a).chart('ZZZ', range: '1mo'), throwsA(isA<NotFoundFailure>()));
  });

  test('network errors map to NetworkFailure', () async {
    final a = FakeAdapter((o) => throw DioException.connectionError(requestOptions: o, reason: 'offline'));
    await expectLater(make(a).search('x'), throwsA(isA<NetworkFailure>()));
  });

  group('crumb handling', () {
    test('attaches crumb, refetches it once on 401 and retries', () async {
      var crumbs = 0;
      final a = FakeAdapter((o) {
        if (o.uri.host == 'fc.yahoo.com') return body('', 404);
        if (o.uri.path == '/v1/test/getcrumb') return body('crumb${++crumbs}', 200);
        if (o.queryParameters['crumb'] == 'crumb1') return body('{"finance":{"error":"Unauthorized"}}', 401);
        return body(fixtureText('quote_batch.json'), 200);
      });
      final dio = Dio()..httpClientAdapter = a;
      final client = YahooClient(dio: dio, config: const YahooConfig(), crumbManager: CrumbManager(dio), backoff: (_) async {});
      final r = await client.quote(['AAPL']);
      expect(r['quoteResponse'], isNotNull);
      expect(crumbs, 2);
      final quoteCalls = a.requests.where((r) => r.uri.path == '/v7/finance/quote').toList();
      expect(quoteCalls.map((r) => r.queryParameters['crumb']), ['crumb1', 'crumb2']);
    });

    test('proxy mode never fetches a crumb', () async {
      final a = FakeAdapter((o) => body(fixtureText('quote_batch.json'), 200));
      final client = make(a, config: const YahooConfig(proxyBase: 'https://proxy.example.com'));
      await client.quote(['AAPL']);
      expect(a.requests.single.uri.host, 'proxy.example.com');
      expect(a.requests.single.queryParameters.containsKey('crumb'), isFalse);
    });
  });

  _webConfigTests();

  test('YahooConfig strips trailing slashes and falls back', () {
    expect(YahooConfig.resolve(override: 'https://x.dev/').proxyBase, 'https://x.dev');
    expect(YahooConfig.resolve(override: '  ').viaProxy, isFalse);
  });
}

void _webConfigTests() {
  test('web without a proxy fails fast with a ConfigFailure and never touches the network', () async {
    final a = FakeAdapter((o) => body('{}', 200));
    final c = make(a, config: const YahooConfig(isWeb: true));
    await expectLater(c.search('x'), throwsA(isA<ConfigFailure>()));
    expect(a.requests, isEmpty);
    expect(const YahooConfig(isWeb: true).misconfigured, isTrue);
    expect(const YahooConfig(isWeb: true, proxyBase: 'https://p.example').misconfigured, isFalse);
    expect(const YahooConfig().misconfigured, isFalse);
  });
}
