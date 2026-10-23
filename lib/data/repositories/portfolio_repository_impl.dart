import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../db/app_database.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  PortfolioRepositoryImpl(this._db, [this._clock = const SystemClock()]);

  final AppDatabase _db;
  final Clock _clock;

  // ---- portfolios ----------------------------------------------------------

  Portfolio _portfolio(PortfolioRow r) => Portfolio(
    id: r.id,
    name: r.name,
    description: r.description,
    color: r.color,
    costMethod: CostMethod.parse(r.costBasisMethod),
    sortOrder: r.sortOrder,
    archived: r.archived,
    createdAt: r.createdAt,
  );

  SimpleSelectStatement<$PortfoliosTable, PortfolioRow> _portfolioQuery() =>
      _db.select(_db.portfolios)..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]);

  @override
  Stream<List<Portfolio>> watchPortfolios() => _portfolioQuery().watch().map((rows) => rows.map(_portfolio).toList());

  @override
  Future<List<Portfolio>> getPortfolios() async => (await _portfolioQuery().get()).map(_portfolio).toList();

  @override
  Future<int> createPortfolio(NewPortfolio p) async {
    final maxOrder = await (_db.selectOnly(
      _db.portfolios,
    )..addColumns([_db.portfolios.sortOrder.max()])).map((r) => r.read(_db.portfolios.sortOrder.max())).getSingle();
    return _db
        .into(_db.portfolios)
        .insert(
          PortfoliosCompanion.insert(
            name: p.name.trim(),
            description: Value(p.description),
            color: Value(p.color),
            costBasisMethod: Value(p.costMethod.name),
            sortOrder: Value((maxOrder ?? -1) + 1),
            createdAt: _clock.now(),
          ),
        );
  }

  @override
  Future<void> updatePortfolio(Portfolio p) => (_db.update(_db.portfolios)..where((t) => t.id.equals(p.id))).write(
    PortfoliosCompanion(
      name: Value(p.name.trim()),
      description: Value(p.description),
      color: Value(p.color),
      costBasisMethod: Value(p.costMethod.name),
      sortOrder: Value(p.sortOrder),
      archived: Value(p.archived),
    ),
  );

  @override
  Future<void> deletePortfolio(int id) => (_db.delete(_db.portfolios)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> reorderPortfolios(List<int> orderedIds) => _db.transaction(() async {
    for (var i = 0; i < orderedIds.length; i++) {
      await (_db.update(_db.portfolios)..where((t) => t.id.equals(orderedIds[i]))).write(PortfoliosCompanion(sortOrder: Value(i)));
    }
  });

  // ---- transactions --------------------------------------------------------

  PortfolioTransaction _tx(TransactionRow r) => PortfolioTransaction(
    id: r.id,
    portfolioId: r.portfolioId,
    symbol: r.symbol,
    type: TxType.parse(r.type),
    tradeDate: r.tradeDate,
    quantity: r.quantity,
    price: r.price,
    fees: r.fees,
    currency: r.currency,
    fxRateToBase: r.fxRateToBase,
    notes: r.notes,
    importBatchId: r.importBatchId,
    createdAt: r.createdAt,
    source: TxSource.parse(r.source),
    connectionId: r.connectionId,
    externalId: r.externalId,
    executedAt: r.executedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.executedAt!, isUtc: true),
  );

  TransactionsCompanion _companion(PortfolioTransaction t, {bool withId = false}) => TransactionsCompanion(
    id: withId ? Value(t.id) : const Value.absent(),
    portfolioId: Value(t.portfolioId),
    symbol: Value(t.symbol),
    type: Value(t.type.dbName),
    tradeDate: Value(dateOnly(t.tradeDate)),
    quantity: Value(t.quantity),
    price: Value(t.price),
    fees: Value(t.fees),
    currency: Value(t.currency),
    fxRateToBase: Value(t.fxRateToBase),
    notes: Value(t.notes),
    importBatchId: Value(t.importBatchId),
    createdAt: Value(t.createdAt),
    source: Value(t.source.name),
    connectionId: Value(t.connectionId),
    externalId: Value(t.externalId),
    executedAt: Value(t.executedAt?.millisecondsSinceEpoch),
  );

  SimpleSelectStatement<$TransactionsTable, TransactionRow> _txQuery() =>
      _db.select(_db.transactions)..orderBy([(t) => OrderingTerm.desc(t.tradeDate), (t) => OrderingTerm.desc(t.id)]);

  @override
  Stream<List<PortfolioTransaction>> watchTransactions() => _txQuery().watch().map((rows) => rows.map(_tx).toList());

  @override
  Future<List<PortfolioTransaction>> getTransactions() async => (await _txQuery().get()).map(_tx).toList();

  @override
  Future<int> addTransaction(PortfolioTransaction t) => _db.into(_db.transactions).insert(_companion(t));

  @override
  Future<void> addTransactions(List<PortfolioTransaction> txs) => _db.batch((b) {
    b.insertAll(_db.transactions, txs.map(_companion).toList());
  });

  @override
  Future<void> updateTransaction(PortfolioTransaction t) =>
      (_db.update(_db.transactions)..where((x) => x.id.equals(t.id))).write(_companion(t));

  @override
  Future<void> deleteTransaction(int id) => (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

  @override
  Future<int> deleteImportBatch(String batchId) => (_db.delete(_db.transactions)..where((t) => t.importBatchId.equals(batchId))).go();

  // ---- instruments ---------------------------------------------------------

  Map<String, Instrument> _instruments(List<InstrumentRow> rows) => {
    for (final r in rows)
      r.symbol: Instrument(
        symbol: r.symbol,
        name: r.name,
        quoteType: r.quoteType,
        exchange: r.exchange,
        currency: r.currency,
        sector: r.sector,
        industry: r.industry,
      ),
  };

  @override
  Stream<Map<String, Instrument>> watchInstruments() => _db.select(_db.instruments).watch().map(_instruments);

  @override
  Future<Map<String, Instrument>> getInstruments() async => _instruments(await _db.select(_db.instruments).get());

  @override
  Future<void> upsertInstrument(Instrument i) => _db
      .into(_db.instruments)
      .insertOnConflictUpdate(
        InstrumentsCompanion.insert(
          symbol: i.symbol,
          name: i.name,
          quoteType: Value(i.quoteType),
          exchange: Value(i.exchange),
          currency: Value(i.currency),
          sector: Value(i.sector),
          industry: Value(i.industry),
          lastMetaRefresh: Value(_clock.now()),
        ),
      );

  // ---- watchlists ----------------------------------------------------------

  Future<List<Watchlist>> _loadWatchlists() async {
    final lists = await (_db.select(_db.watchlists)..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)])).get();
    final items = await (_db.select(_db.watchlistItems)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
    return [
      for (final l in lists)
        Watchlist(
          id: l.id,
          name: l.name,
          sortOrder: l.sortOrder,
          symbols: [
            for (final i in items)
              if (i.watchlistId == l.id) i.symbol,
          ],
        ),
    ];
  }

  @override
  Stream<List<Watchlist>> watchWatchlists() =>
      _db.customSelect('SELECT 1', readsFrom: {_db.watchlists, _db.watchlistItems}).watch().asyncMap((_) => _loadWatchlists());

  @override
  Future<List<Watchlist>> getWatchlists() => _loadWatchlists();

  @override
  Future<int> createWatchlist(String name) async {
    final maxOrder = await (_db.selectOnly(
      _db.watchlists,
    )..addColumns([_db.watchlists.sortOrder.max()])).map((r) => r.read(_db.watchlists.sortOrder.max())).getSingle();
    return _db.into(_db.watchlists).insert(WatchlistsCompanion.insert(name: name.trim(), sortOrder: Value((maxOrder ?? -1) + 1)));
  }

  @override
  Future<void> renameWatchlist(int id, String name) =>
      (_db.update(_db.watchlists)..where((t) => t.id.equals(id))).write(WatchlistsCompanion(name: Value(name.trim())));

  @override
  Future<void> deleteWatchlist(int id) => (_db.delete(_db.watchlists)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> addToWatchlist(int id, String symbol) async {
    final maxOrder =
        await (_db.selectOnly(_db.watchlistItems)
              ..addColumns([_db.watchlistItems.sortOrder.max()])
              ..where(_db.watchlistItems.watchlistId.equals(id)))
            .map((r) => r.read(_db.watchlistItems.sortOrder.max()))
            .getSingle();
    await _db
        .into(_db.watchlistItems)
        .insert(
          WatchlistItemsCompanion.insert(watchlistId: id, symbol: symbol, sortOrder: Value((maxOrder ?? -1) + 1)),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<void> removeFromWatchlist(int id, String symbol) =>
      (_db.delete(_db.watchlistItems)..where((t) => t.watchlistId.equals(id) & t.symbol.equals(symbol))).go();

  @override
  Future<void> reorderWatchlistItems(int id, List<String> orderedSymbols) => _db.transaction(() async {
    for (var i = 0; i < orderedSymbols.length; i++) {
      await (_db.update(
        _db.watchlistItems,
      )..where((t) => t.watchlistId.equals(id) & t.symbol.equals(orderedSymbols[i]))).write(WatchlistItemsCompanion(sortOrder: Value(i)));
    }
  });

  // ---- import mappings -----------------------------------------------------

  @override
  Stream<List<ImportMapping>> watchImportMappings() => _db
      .select(_db.importMappings)
      .watch()
      .map(
        (rows) => [
          for (final r in rows) ImportMapping(id: r.id, name: r.name, mapping: (jsonDecode(r.mappingJson) as Map).cast<String, Object?>()),
        ],
      );

  @override
  Future<void> saveImportMapping(String name, Map<String, Object?> mapping) async {
    final existing = await (_db.select(_db.importMappings)..where((t) => t.name.equals(name))).getSingleOrNull();
    if (existing != null) {
      await (_db.update(
        _db.importMappings,
      )..where((t) => t.id.equals(existing.id))).write(ImportMappingsCompanion(mappingJson: Value(jsonEncode(mapping))));
    } else {
      await _db.into(_db.importMappings).insert(ImportMappingsCompanion.insert(name: name, mappingJson: jsonEncode(mapping)));
    }
  }

  @override
  Future<void> deleteImportMapping(int id) => (_db.delete(_db.importMappings)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> wipeUserData() => _db.transaction(() async {
    await _db.delete(_db.lunoLedgerRows).go();
    await _db.delete(_db.lunoAccountCursors).go();
    await _db.delete(_db.lunoConnections).go();
    await _db.delete(_db.lunoMarketsCache).go();
    await _db.delete(_db.transactions).go();
    await _db.delete(_db.portfolios).go();
    await _db.delete(_db.watchlistItems).go();
    await _db.delete(_db.watchlists).go();
    await _db.delete(_db.instruments).go();
    await _db.delete(_db.importMappings).go();
  });
}
