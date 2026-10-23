import 'package:decimal/decimal.dart';

import '../../core/clock.dart';
import '../../core/decimal_ext.dart';
import '../../core/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/market.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/repositories/market_data_repository.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/services/csv_import.dart';
import '../../domain/services/fx.dart';

class ImportResult {
  const ImportResult({required this.batchId, required this.imported, required this.fxFallbacks, required this.currencyFallbacks});

  final String batchId;
  final int imported;

  /// Rows whose exchange rate could not be found and defaulted to the latest/1.0.
  final int fxFallbacks;

  /// Symbols whose currency was unknown and defaulted.
  final int currencyFallbacks;
}

/// Turns validated [ImportRow]s into stored transactions: resolves currencies and historical FX.
class ImportCommitter {
  ImportCommitter({required this.portfolios, required this.market, required this.clock});

  final PortfolioRepository portfolios;
  final MarketDataRepository market;
  final Clock clock;

  Future<ImportResult> commit({
    required int portfolioId,
    required List<ImportRow> rows,
    required String baseCurrency,
    required Map<String, Quote> knownQuotes,
    required FxRates currentFx,
    String? defaultCurrency,
  }) async {
    final now = clock.now();
    final batchId = 'import-${now.toUtc().millisecondsSinceEpoch}';
    final usable = rows.where((r) => r.valid && r.date != null && r.type != null).toList();

    // 1) Currencies for symbols whose rows carry none.
    final quotes = {...knownQuotes};
    final needQuote = {
      for (final r in usable)
        if (r.symbol != null && r.currency == null && quotes[r.symbol] == null) r.symbol!,
    };
    if (needQuote.isNotEmpty) {
      await market.refreshQuotes(needQuote);
      quotes.addAll(await market.quotesSnapshot());
    }
    var currencyFallbacks = 0;
    String currencyFor(ImportRow r) {
      if (!(r.type?.hasSymbol ?? true)) return baseCurrency;
      final c = r.currency ?? quotes[r.symbol]?.currency;
      if (c != null) return c;
      currencyFallbacks++;
      return defaultCurrency ?? baseCurrency;
    }

    final currencies = [for (final r in usable) currencyFor(r)];

    // 2) Historical FX per foreign currency, fetched once from the earliest trade date.
    final foreign = {
      for (final c in currencies)
        if (c != baseCurrency) c,
    };
    final series = <String, FxSeries>{};
    final earliest = usable.isEmpty ? now : usable.map((r) => r.date!).reduce((a, b) => a.isBefore(b) ? a : b);
    for (final c in foreign) {
      final r = await market.dailyHistory(fxSymbol(c, baseCurrency), earliest.subtract(const Duration(days: 10)));
      if (r case Ok(:final value) when value.candles.isNotEmpty) {
        series[c] = FxSeries([for (final x in value.candles) x.time], [for (final x in value.candles) dec(x.close)]);
      }
    }
    var fxFallbacks = 0;
    Decimal fxFor(String currency, DateTime date) {
      if (currency == baseCurrency) return Decimal.one;
      final hist = series[currency]?.at(date);
      if (hist != null) return hist;
      fxFallbacks++;
      return currentFx.rate(currency, baseCurrency) ?? Decimal.one;
    }

    // 3) Build and store.
    final txs = <PortfolioTransaction>[];
    for (var i = 0; i < usable.length; i++) {
      final r = usable[i];
      final ccy = currencies[i];
      txs.add(
        PortfolioTransaction(
          id: 0,
          portfolioId: portfolioId,
          symbol: r.type!.hasSymbol ? r.symbol : null,
          type: r.type!,
          tradeDate: r.date!,
          quantity: r.quantity ?? Decimal.one,
          price: r.price ?? Decimal.zero,
          fees: r.fees ?? Decimal.zero,
          currency: ccy,
          fxRateToBase: fxFor(ccy, r.date!),
          notes: r.notes,
          importBatchId: batchId,
          createdAt: now,
          source: TxSource.csv,
        ),
      );
    }
    if (txs.isNotEmpty) await portfolios.addTransactions(txs);

    // Remember instruments we learned about, then fetch prices for them in the background.
    final symbols = {for (final t in txs) ?t.symbol};
    for (final s in symbols) {
      final q = quotes[s];
      await portfolios.upsertInstrument(
        Instrument(
          symbol: s,
          name: q?.name ?? s,
          quoteType: q?.quoteType,
          exchange: q?.exchange,
          currency: q?.currency ?? txs.firstWhere((t) => t.symbol == s).currency,
          sector: q?.sector,
          industry: q?.industry,
        ),
      );
    }
    if (symbols.isNotEmpty) {
      // Fire and forget: prices appear on the dashboard when they arrive.
      market.refreshQuotes({...symbols, for (final c in foreign) fxSymbol(c, baseCurrency)});
    }

    return ImportResult(batchId: batchId, imported: txs.length, fxFallbacks: fxFallbacks, currencyFallbacks: currencyFallbacks);
  }
}
