import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/yahoo/yahoo_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  final now = DateTime.utc(2024, 1, 10);

  group('chart', () {
    test('parses candles, skipping null candles, using exchange-local dates', () {
      final h = YahooMappers.chart(fixture('chart_equity.json'), intraday: false);
      expect(h.symbol, 'AAPL');
      expect(h.currency, 'USD');
      expect(h.candles.length, 4); // 5 timestamps, one null candle
      expect(h.candles.first.time, DateTime.utc(2024, 1, 2));
      expect(h.candles.first.close, 188.0);
      expect(h.candles.first.adjClose, 187.5);
      expect(h.candles.last.close, 190.5);
      expect(h.candles.map((c) => c.time), isNot(contains(DateTime.utc(2024, 1, 4)))); // null candle skipped
    });

    test('parses dividend and split events', () {
      final h = YahooMappers.chart(fixture('chart_equity.json'), intraday: false);
      expect(h.dividends.single.amount, 0.24);
      expect(h.dividends.single.exDate, DateTime.utc(2024, 1, 3));
      expect(h.splits.single.numerator, 4);
      expect(h.splits.single.denominator, 1);
      expect(h.splits.single.date, DateTime.utc(2024, 1, 4));
    });

    test('normalises GBp pence to GBP pounds', () {
      final h = YahooMappers.chart(fixture('chart_gbp_pence.json'), intraday: false);
      expect(h.currency, 'GBP');
      expect(h.candles.last.close, closeTo(0.725, 1e-9));
      expect(h.candles.first.high, closeTo(0.715, 1e-9));
      expect(h.candles.last.volume, 6000); // volume is not scaled
    });

    test('intraday keeps instants', () {
      final h = YahooMappers.chart(fixture('chart_equity.json'), intraday: true);
      expect(h.candles.first.time, DateTime.utc(2024, 1, 2, 14, 30));
    });

    test('error payload becomes NotFoundFailure', () {
      expect(() => YahooMappers.chart(fixture('chart_error.json'), intraday: false), throwsA(isA<NotFoundFailure>()));
    });

    test('result without timestamps yields an empty history', () {
      final h = YahooMappers.chart(fixture('chart_empty.json'), intraday: false);
      expect(h.candles, isEmpty);
    });

    test('malformed body throws ParseFailure', () {
      expect(() => YahooMappers.chart(<String, Object?>{}, intraday: false), throwsA(isA<ParseFailure>()));
      expect(() => decodeJson('<html>'), throwsA(isA<ParseFailure>()));
    });
  });

  group('quotes', () {
    final quotes = YahooMappers.quotes(fixture('quote_batch.json'), now);
    final bySymbol = {for (final q in quotes) q.symbol: q};

    test('parses fields', () {
      final a = bySymbol['AAPL']!;
      expect(a.name, 'Apple Inc.');
      expect(a.price, 190.5);
      expect(a.previousClose, 187.0);
      expect(a.change, closeTo(3.5, 1e-9));
      expect(a.changePct, closeTo(3.5 / 187.0, 1e-9));
      expect(a.exchange, 'NasdaqGS');
      expect(a.dividendYield, 0.0051);
      expect(a.quoteType, 'EQUITY');
    });

    test('normalises pence quotes including 52-week range and EPS', () {
      final v = bySymbol['VOD.L']!;
      expect(v.currency, 'GBP');
      expect(v.price, closeTo(0.725, 1e-9));
      expect(v.fiftyTwoWeekHigh, closeTo(0.95, 1e-9));
      expect(v.eps, closeTo(-0.025, 1e-9));
    });

    test('tolerates nulls and defaults currency', () {
      final w = bySymbol['WEIRD']!;
      expect(w.price, isNull);
      expect(w.change, isNull);
      expect(w.currency, 'USD');
    });

    test('quote json round-trips', () {
      final a = bySymbol['AAPL']!;
      final r = a.runtimeType == a.runtimeType ? a : a;
      expect(r.toJson()['symbol'], 'AAPL');
    });
  });

  test('search parses quotes and news, dropping malformed rows', () {
    final r = YahooMappers.search(fixture('search.json'));
    expect(r.results.map((e) => e.symbol), ['AAPL', 'APLE', 'NOTYPE']);
    expect(r.results.first.exchange, 'NASDAQ');
    expect(r.news.length, 1);
    expect(r.news.single.publisher, 'Reuters');
    expect(r.news.single.publishedAt, DateTime.utc(2024, 1, 2, 14, 30));
  });

  group('profile', () {
    test('parses quoteSummary', () {
      final p = YahooMappers.profile(fixture('quote_summary.json'));
      expect(p.sector, 'Technology');
      expect(p.employees, 164000);
      expect(p.beta, 1.29);
      expect(p.dividendYield, 0.0051);
      expect(p.eps, 6.1);
      expect(p.events.exDividendDate, DateTime.utc(2024, 2, 9));
      expect(p.events.earningsDate, DateTime.utc(2024, 2, 2));
    });

    test('error becomes NotFoundFailure', () {
      expect(() => YahooMappers.profile(fixture('quote_summary_error.json')), throwsA(isA<NotFoundFailure>()));
    });
  });

  test('normaliseCurrency', () {
    expect(normaliseCurrency('GBp'), ('GBP', 0.01));
    expect(normaliseCurrency('ZAc'), ('ZAR', 0.01));
    expect(normaliseCurrency('ILA'), ('ILS', 0.01));
    expect(normaliseCurrency('EUR'), ('EUR', 1.0));
    expect(normaliseCurrency(null), ('USD', 1.0));
  });
}
