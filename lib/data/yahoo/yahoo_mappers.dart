import 'dart:convert';

import '../../core/failure.dart';
import '../../domain/entities/market.dart';

typedef Json = Map<String, Object?>;

/// Currency codes quoted in minor units, mapped to (major code, divisor).
const _minorUnits = <String, (String, double)>{
  'GBp': ('GBP', 100),
  'GBX': ('GBP', 100),
  'ZAc': ('ZAR', 100),
  'ZAC': ('ZAR', 100),
  'ILA': ('ILS', 100),
};

/// Returns (majorCurrency, priceScale) for a Yahoo currency code.
(String, double) normaliseCurrency(String? code) {
  if (code == null || code.isEmpty) return ('USD', 1);
  final minor = _minorUnits[code];
  if (minor != null) return (minor.$1, 1 / minor.$2);
  return (code, 1);
}

double? _num(Object? v) {
  if (v is num) return v.isFinite ? v.toDouble() : null;
  if (v is Json) return _num(v['raw']);
  return null;
}

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

DateTime? _epoch(Object? v) {
  final n = _num(v);
  return n == null ? null : DateTime.fromMillisecondsSinceEpoch(n.toInt() * 1000, isUtc: true);
}

/// Exchange-local calendar date (UTC midnight) for an epoch timestamp.
DateTime localDate(int epochSeconds, int gmtOffset) {
  final d = DateTime.fromMillisecondsSinceEpoch((epochSeconds + gmtOffset) * 1000, isUtc: true);
  return DateTime.utc(d.year, d.month, d.day);
}

Json decodeJson(String body) {
  try {
    final v = jsonDecode(body);
    if (v is Json) return v;
  } on FormatException {
    // fall through
  }
  throw const ParseFailure('Response was not a JSON object');
}

AppFailure _errorFrom(Object? error) {
  final e = error is Json ? error : const <String, Object?>{};
  final code = '${e['code'] ?? ''}'.toLowerCase();
  final desc = _str(e['description']) ?? 'Request failed';
  if (code.contains('not found')) return NotFoundFailure(desc);
  if (code.contains('too many')) return RateLimitedFailure(desc);
  if (code.contains('unauthorized')) return UnauthorizedFailure(desc);
  return ParseFailure(desc);
}

class YahooMappers {
  const YahooMappers._();

  /// Parses `/v8/finance/chart` into a [PriceHistory].
  ///
  /// [intraday] candles keep their instant; daily+ candles use the exchange-local date.
  static PriceHistory chart(Json body, {required bool intraday, String? fallbackSymbol}) {
    final chart = body['chart'];
    if (chart is! Json) throw const ParseFailure('Missing chart object');
    final error = chart['error'];
    if (error != null) throw _errorFrom(error);
    final results = chart['result'];
    if (results is! List || results.isEmpty) throw const NotFoundFailure('No data found');
    final r = results.first;
    if (r is! Json) throw const ParseFailure('Malformed chart result');

    final meta = r['meta'] is Json ? r['meta']! as Json : const <String, Object?>{};
    final symbol = _str(meta['symbol']) ?? fallbackSymbol ?? '';
    final (currency, scale) = normaliseCurrency(_str(meta['currency']));
    final offset = (_num(meta['gmtoffset']) ?? 0).toInt();

    final stamps = (r['timestamp'] as List?)?.cast<Object?>() ?? const [];
    final indicators = r['indicators'] is Json ? r['indicators']! as Json : const <String, Object?>{};
    final quote = _firstJson(indicators['quote']);
    final adj = _firstJson(indicators['adjclose']);
    List<Object?> col(Json? j, String k) => (j?[k] as List?)?.cast<Object?>() ?? const [];
    final o = col(quote, 'open'), h = col(quote, 'high'), l = col(quote, 'low'), c = col(quote, 'close'), v = col(quote, 'volume');
    final a = col(adj, 'adjclose');

    final candles = <Candle>[];
    for (var i = 0; i < stamps.length; i++) {
      final ts = _num(stamps[i]);
      final close = i < c.length ? _num(c[i]) : null;
      if (ts == null || close == null) continue; // null candle (halt / no trade)
      final open = (i < o.length ? _num(o[i]) : null) ?? close;
      final high = (i < h.length ? _num(h[i]) : null) ?? close;
      final low = (i < l.length ? _num(l[i]) : null) ?? close;
      final adjClose = i < a.length ? _num(a[i]) : null;
      candles.add(
        Candle(
          time: intraday ? DateTime.fromMillisecondsSinceEpoch(ts.toInt() * 1000, isUtc: true) : localDate(ts.toInt(), offset),
          open: open * scale,
          high: high * scale,
          low: low * scale,
          close: close * scale,
          adjClose: adjClose == null ? null : adjClose * scale,
          volume: (i < v.length ? _num(v[i]) : null) ?? 0,
        ),
      );
    }

    final events = r['events'] is Json ? r['events']! as Json : const <String, Object?>{};
    final dividends = <DividendEvent>[];
    final divs = events['dividends'];
    if (divs is Json) {
      for (final e in divs.values) {
        if (e is! Json) continue;
        final ts = _num(e['date']);
        final amount = _num(e['amount']);
        if (ts == null || amount == null) continue;
        dividends.add(DividendEvent(symbol: symbol, exDate: localDate(ts.toInt(), offset), amount: amount * scale));
      }
    }
    final splits = <SplitEvent>[];
    final sp = events['splits'];
    if (sp is Json) {
      for (final e in sp.values) {
        if (e is! Json) continue;
        final ts = _num(e['date']);
        final n = _num(e['numerator']);
        final d = _num(e['denominator']);
        if (ts == null || n == null || d == null || d == 0) continue;
        splits.add(SplitEvent(symbol: symbol, date: localDate(ts.toInt(), offset), numerator: n.toInt(), denominator: d.toInt()));
      }
    }
    dividends.sort((x, y) => x.exDate.compareTo(y.exDate));
    splits.sort((x, y) => x.date.compareTo(y.date));
    return PriceHistory(symbol: symbol, candles: candles, dividends: dividends, splits: splits, currency: currency);
  }

  static Json? _firstJson(Object? list) => list is List && list.isNotEmpty && list.first is Json ? list.first as Json : null;

  /// Parses `/v7/finance/quote` into quotes keyed by symbol. Unusable rows are skipped.
  static List<Quote> quotes(Json body, DateTime fetchedAt) {
    final qr = body['quoteResponse'];
    if (qr is! Json) throw const ParseFailure('Missing quoteResponse');
    if (qr['error'] != null) throw _errorFrom(qr['error']);
    final result = qr['result'];
    if (result is! List) return const [];
    final out = <Quote>[];
    for (final row in result) {
      if (row is! Json) continue;
      final symbol = _str(row['symbol']);
      if (symbol == null) continue;
      final (currency, scale) = normaliseCurrency(_str(row['currency']));
      double? px(String k) {
        final n = _num(row[k]);
        return n == null ? null : n * scale;
      }

      double? dividendYield = _num(row['trailingAnnualDividendYield']);
      if (dividendYield == null) {
        final y = _num(row['dividendYield']);
        if (y != null) dividendYield = y / 100; // reported as a percentage
      }
      out.add(
        Quote(
          symbol: symbol,
          name: _str(row['longName']) ?? _str(row['shortName']) ?? _str(row['displayName']),
          price: px('regularMarketPrice'),
          previousClose: px('regularMarketPreviousClose'),
          open: px('regularMarketOpen'),
          dayHigh: px('regularMarketDayHigh'),
          dayLow: px('regularMarketDayLow'),
          volume: _num(row['regularMarketVolume']),
          marketCap: _num(row['marketCap']),
          fiftyTwoWeekHigh: px('fiftyTwoWeekHigh'),
          fiftyTwoWeekLow: px('fiftyTwoWeekLow'),
          trailingPE: _num(row['trailingPE']),
          eps: px('epsTrailingTwelveMonths'),
          dividendYield: dividendYield,
          currency: currency,
          quoteType: _str(row['quoteType']),
          exchange: _str(row['fullExchangeName']) ?? _str(row['exchange']),
          marketState: _str(row['marketState']),
          timeZone: _str(row['exchangeTimezoneName']),
          fetchedAt: fetchedAt,
        ),
      );
    }
    return out;
  }

  /// Parses `/v1/finance/search`.
  static SearchResponse search(Json body) {
    final results = <SearchResult>[];
    for (final q in (body['quotes'] as List?) ?? const []) {
      if (q is! Json) continue;
      final symbol = _str(q['symbol']);
      if (symbol == null) continue;
      results.add(
        SearchResult(
          symbol: symbol,
          name: _str(q['longname']) ?? _str(q['shortname']) ?? symbol,
          quoteType: _str(q['quoteType']),
          exchange: _str(q['exchDisp']) ?? _str(q['exchange']),
        ),
      );
    }
    final news = <NewsItem>[];
    for (final n in (body['news'] as List?) ?? const []) {
      if (n is! Json) continue;
      final title = _str(n['title']);
      final link = _str(n['link']);
      if (title == null || link == null) continue;
      news.add(NewsItem(title: title, url: link, publisher: _str(n['publisher']), publishedAt: _epoch(n['providerPublishTime'])));
    }
    return SearchResponse(results: results, news: news);
  }

  /// Parses `/v10/finance/quoteSummary` into an [AssetProfile].
  static AssetProfile profile(Json body) {
    final qs = body['quoteSummary'];
    if (qs is! Json) throw const ParseFailure('Missing quoteSummary');
    if (qs['error'] != null) throw _errorFrom(qs['error']);
    final result = qs['result'];
    if (result is! List || result.isEmpty || result.first is! Json) throw const NotFoundFailure('No profile found');
    final r = result.first as Json;
    Json m(String k) => r[k] is Json ? r[k]! as Json : const <String, Object?>{};
    final ap = m('assetProfile'), sd = m('summaryDetail'), ks = m('defaultKeyStatistics'), ce = m('calendarEvents');
    final earnings = ce['earnings'] is Json ? ce['earnings']! as Json : const <String, Object?>{};
    final earningsDates = earnings['earningsDate'];
    return AssetProfile(
      description: _str(ap['longBusinessSummary']),
      website: _str(ap['website']),
      sector: _str(ap['sector']),
      industry: _str(ap['industry']),
      country: _str(ap['country']),
      employees: _num(ap['fullTimeEmployees'])?.toInt(),
      beta: _num(sd['beta']) ?? _num(ks['beta']),
      trailingPE: _num(sd['trailingPE']),
      eps: _num(ks['trailingEps']),
      dividendYield: _num(sd['dividendYield']) ?? _num(sd['trailingAnnualDividendYield']),
      events: UpcomingEvents(
        exDividendDate: _epoch(ce['exDividendDate']),
        dividendPayDate: _epoch(ce['dividendDate']),
        earningsDate: earningsDates is List && earningsDates.isNotEmpty ? _epoch(earningsDates.first) : null,
      ),
    );
  }
}
