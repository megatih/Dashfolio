import 'package:decimal/decimal.dart';

/// A live/last quote for an instrument. Prices are in [currency] major units
/// (minor-unit currencies such as GBp are normalised by the Yahoo mapper).
class Quote {
  const Quote({
    required this.symbol,
    this.name,
    this.price,
    this.previousClose,
    this.open,
    this.dayHigh,
    this.dayLow,
    this.volume,
    this.marketCap,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.trailingPE,
    this.eps,
    this.dividendYield,
    this.beta,
    this.currency = 'USD',
    this.quoteType,
    this.exchange,
    this.marketState,
    this.sector,
    this.industry,
    this.timeZone,
    this.bid,
    this.ask,
    required this.fetchedAt,
  });

  final String symbol;
  final String? name;
  final double? price;
  final double? previousClose;
  final double? open;
  final double? dayHigh;
  final double? dayLow;
  final double? volume;
  final double? marketCap;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final double? trailingPE;
  final double? eps;
  final double? dividendYield;
  final double? beta;
  final String currency;
  final String? quoteType;
  final String? exchange;
  final String? marketState;
  final String? sector;
  final String? industry;
  final String? timeZone;

  /// Best bid / ask (exchange sources such as Luno).
  final double? bid;
  final double? ask;
  final DateTime fetchedAt;

  double? get change => (price != null && previousClose != null) ? price! - previousClose! : null;

  double? get changePct => (change != null && previousClose != null && previousClose != 0) ? change! / previousClose! : null;

  Decimal? get priceDec => price == null ? null : Decimal.parse(price!.toString());

  Quote copyWith({String? sector, String? industry, double? beta, double? trailingPE, double? eps, double? dividendYield}) => Quote(
    symbol: symbol,
    name: name,
    price: price,
    previousClose: previousClose,
    open: open,
    dayHigh: dayHigh,
    dayLow: dayLow,
    volume: volume,
    marketCap: marketCap,
    fiftyTwoWeekHigh: fiftyTwoWeekHigh,
    fiftyTwoWeekLow: fiftyTwoWeekLow,
    trailingPE: trailingPE ?? this.trailingPE,
    eps: eps ?? this.eps,
    dividendYield: dividendYield ?? this.dividendYield,
    beta: beta ?? this.beta,
    currency: currency,
    quoteType: quoteType,
    exchange: exchange,
    marketState: marketState,
    sector: sector ?? this.sector,
    industry: industry ?? this.industry,
    timeZone: timeZone,
    bid: bid,
    ask: ask,
    fetchedAt: fetchedAt,
  );

  Map<String, Object?> toJson() => {
    'symbol': symbol,
    'name': name,
    'price': price,
    'previousClose': previousClose,
    'open': open,
    'dayHigh': dayHigh,
    'dayLow': dayLow,
    'volume': volume,
    'marketCap': marketCap,
    'fiftyTwoWeekHigh': fiftyTwoWeekHigh,
    'fiftyTwoWeekLow': fiftyTwoWeekLow,
    'trailingPE': trailingPE,
    'eps': eps,
    'dividendYield': dividendYield,
    'beta': beta,
    'currency': currency,
    'quoteType': quoteType,
    'exchange': exchange,
    'marketState': marketState,
    'sector': sector,
    'industry': industry,
    'timeZone': timeZone,
    'bid': bid,
    'ask': ask,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory Quote.fromJson(Map<String, Object?> j) {
    double? d(String k) => (j[k] as num?)?.toDouble();
    return Quote(
      symbol: j['symbol']! as String,
      name: j['name'] as String?,
      price: d('price'),
      previousClose: d('previousClose'),
      open: d('open'),
      dayHigh: d('dayHigh'),
      dayLow: d('dayLow'),
      volume: d('volume'),
      marketCap: d('marketCap'),
      fiftyTwoWeekHigh: d('fiftyTwoWeekHigh'),
      fiftyTwoWeekLow: d('fiftyTwoWeekLow'),
      trailingPE: d('trailingPE'),
      eps: d('eps'),
      dividendYield: d('dividendYield'),
      beta: d('beta'),
      currency: (j['currency'] as String?) ?? 'USD',
      quoteType: j['quoteType'] as String?,
      exchange: j['exchange'] as String?,
      marketState: j['marketState'] as String?,
      sector: j['sector'] as String?,
      industry: j['industry'] as String?,
      timeZone: j['timeZone'] as String?,
      bid: d('bid'),
      ask: d('ask'),
      fetchedAt: DateTime.tryParse((j['fetchedAt'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class Candle {
  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.adjClose,
    this.volume = 0,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double? adjClose;
  final double volume;
}

class DividendEvent {
  const DividendEvent({required this.symbol, required this.exDate, required this.amount, this.payDate});
  final String symbol;
  final DateTime exDate;
  final double amount;
  final DateTime? payDate;
}

class SplitEvent {
  const SplitEvent({required this.symbol, required this.date, required this.numerator, required this.denominator});
  final String symbol;
  final DateTime date;
  final int numerator;
  final int denominator;
}

class PriceHistory {
  const PriceHistory({
    required this.symbol,
    required this.candles,
    this.dividends = const [],
    this.splits = const [],
    this.currency,
    this.via,
  });
  final String symbol;
  final List<Candle> candles;
  final List<DividendEvent> dividends;
  final List<SplitEvent> splits;
  final String? currency;

  /// Set when the series came from a different provider than the symbol's own (e.g. `Yahoo` for a Luno pair).
  final String? via;
}

class SearchResult {
  const SearchResult({required this.symbol, required this.name, this.quoteType, this.exchange});
  final String symbol;
  final String name;
  final String? quoteType;
  final String? exchange;
}

class NewsItem {
  const NewsItem({required this.title, required this.url, this.publisher, this.publishedAt});
  final String title;
  final String url;
  final String? publisher;
  final DateTime? publishedAt;
}

class SearchResponse {
  const SearchResponse({required this.results, required this.news});
  final List<SearchResult> results;
  final List<NewsItem> news;
}

class UpcomingEvents {
  const UpcomingEvents({this.exDividendDate, this.dividendPayDate, this.earningsDate});
  final DateTime? exDividendDate;
  final DateTime? dividendPayDate;
  final DateTime? earningsDate;
}

class AssetProfile {
  const AssetProfile({
    this.description,
    this.website,
    this.sector,
    this.industry,
    this.country,
    this.employees,
    this.beta,
    this.trailingPE,
    this.eps,
    this.dividendYield,
    this.events = const UpcomingEvents(),
  });
  final String? description;
  final String? website;
  final String? sector;
  final String? industry;
  final String? country;
  final int? employees;
  final double? beta;
  final double? trailingPE;
  final double? eps;

  /// Trailing dividend yield as a ratio (0.0051 = 0.51%).
  final double? dividendYield;
  final UpcomingEvents events;
}
