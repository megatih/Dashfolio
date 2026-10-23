import 'package:decimal/decimal.dart';

import 'enums.dart';

class Portfolio {
  const Portfolio({
    required this.id,
    required this.name,
    this.description,
    this.color = 0xFF3B82F6,
    this.costMethod = CostMethod.average,
    this.sortOrder = 0,
    this.archived = false,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? description;
  final int color;
  final CostMethod costMethod;
  final int sortOrder;
  final bool archived;
  final DateTime createdAt;

  Portfolio copyWith({String? name, String? description, int? color, CostMethod? costMethod, int? sortOrder, bool? archived}) => Portfolio(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    color: color ?? this.color,
    costMethod: costMethod ?? this.costMethod,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt,
  );
}

class PortfolioTransaction {
  const PortfolioTransaction({
    required this.id,
    required this.portfolioId,
    this.symbol,
    required this.type,
    required this.tradeDate,
    required this.quantity,
    required this.price,
    required this.fees,
    required this.currency,
    required this.fxRateToBase,
    this.notes,
    this.importBatchId,
    required this.createdAt,
    this.source = TxSource.manual,
    this.connectionId,
    this.externalId,
    this.executedAt,
  });

  final int id;
  final int portfolioId;
  final String? symbol;
  final TxType type;

  /// Date-only (UTC midnight).
  final DateTime tradeDate;
  final Decimal quantity;
  final Decimal price;
  final Decimal fees;
  final String currency;

  /// Rate converting [currency] → base currency at entry time.
  final Decimal fxRateToBase;
  final String? notes;
  final String? importBatchId;
  final DateTime createdAt;

  /// Provenance; `luno` rows are synced and read-only.
  final TxSource source;
  final int? connectionId;

  /// Stable id from the source system, unique per [connectionId] (idempotent re-sync).
  final String? externalId;

  /// Execution instant (UTC); orders transactions within a day when present.
  final DateTime? executedAt;

  bool get isSynced => source == TxSource.luno;

  /// Gross amount in transaction currency (quantity × price).
  Decimal get gross => quantity * price;

  PortfolioTransaction copyWith({int? id, int? portfolioId, Decimal? fxRateToBase, String? notes, bool clearNotes = false}) =>
      PortfolioTransaction(
        id: id ?? this.id,
        portfolioId: portfolioId ?? this.portfolioId,
        symbol: symbol,
        type: type,
        tradeDate: tradeDate,
        quantity: quantity,
        price: price,
        fees: fees,
        currency: currency,
        fxRateToBase: fxRateToBase ?? this.fxRateToBase,
        notes: clearNotes ? null : (notes ?? this.notes),
        importBatchId: importBatchId,
        createdAt: createdAt,
        source: source,
        connectionId: connectionId,
        externalId: externalId,
        executedAt: executedAt,
      );
}

class Instrument {
  const Instrument({
    required this.symbol,
    required this.name,
    this.quoteType,
    this.exchange,
    this.currency = 'USD',
    this.sector,
    this.industry,
  });
  final String symbol;
  final String name;
  final String? quoteType;
  final String? exchange;
  final String currency;
  final String? sector;
  final String? industry;
}

class Watchlist {
  const Watchlist({required this.id, required this.name, this.sortOrder = 0, this.symbols = const []});
  final int id;
  final String name;
  final int sortOrder;
  final List<String> symbols;
}
