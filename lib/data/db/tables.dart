import 'package:drift/drift.dart';

import 'converters.dart';

@DataClassName('PortfolioRow')
class Portfolios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get color => integer().withDefault(const Constant(0xFF3B82F6))();
  TextColumn get costBasisMethod => text().withDefault(const Constant('average'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('InstrumentRow')
class Instruments extends Table {
  TextColumn get symbol => text()();
  TextColumn get name => text()();
  TextColumn get quoteType => text().nullable()();
  TextColumn get exchange => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get sector => text().nullable()();
  TextColumn get industry => text().nullable()();
  DateTimeColumn get lastMetaRefresh => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {symbol};
}

@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_connection_external', columns: {#connectionId, #externalId}, unique: true)
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get portfolioId => integer().references(Portfolios, #id, onDelete: KeyAction.cascade)();
  TextColumn get symbol => text().nullable()();
  TextColumn get type => text()();
  TextColumn get tradeDate => text().map(const DateOnlyConverter())();
  TextColumn get quantity => text().map(const DecimalConverter())();
  TextColumn get price => text().map(const DecimalConverter())();
  TextColumn get fees => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get fxRateToBase => text().map(const DecimalConverter()).withDefault(const Constant('1'))();
  TextColumn get notes => text().nullable()();
  TextColumn get importBatchId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// `manual` | `csv` | `luno`. Luno rows are written only by the sync service.
  TextColumn get source => text().withDefault(const Constant('manual'))();
  IntColumn get connectionId => integer().nullable().references(LunoConnections, #id, onDelete: KeyAction.setNull)();
  TextColumn get externalId => text().nullable()();

  /// Execution time (UTC epoch ms) used for ordering within a day.
  IntColumn get executedAt => integer().nullable()();
}

@DataClassName('WatchlistRow')
class Watchlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('WatchlistItemRow')
class WatchlistItems extends Table {
  IntColumn get watchlistId => integer().references(Watchlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get symbol => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {watchlistId, symbol};
}

@DataClassName('QuoteCacheRow')
class QuoteCache extends Table {
  TextColumn get symbol => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {symbol};
}

@DataClassName('ProfileCacheRow')
class ProfileCache extends Table {
  TextColumn get symbol => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {symbol};
}

@DataClassName('PriceRow')
class PriceHistoryCache extends Table {
  TextColumn get symbol => text()();
  TextColumn get interval => text()();
  IntColumn get ts => integer()(); // epoch seconds (UTC)
  RealColumn get open => real()();
  RealColumn get high => real()();
  RealColumn get low => real()();
  RealColumn get close => real()();
  RealColumn get adjClose => real().nullable()();
  RealColumn get volume => real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {symbol, interval, ts};
}

/// Tracks which window of a symbol/interval series is cached and when it was fetched.
@DataClassName('HistoryMetaRow')
class HistoryMeta extends Table {
  TextColumn get symbol => text()();
  TextColumn get interval => text()();
  IntColumn get oldestTs => integer()();
  IntColumn get newestTs => integer()();
  TextColumn get currency => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {symbol, interval};
}

@DataClassName('DividendRow')
class DividendEventsCache extends Table {
  TextColumn get symbol => text()();
  TextColumn get exDate => text().map(const DateOnlyConverter())();
  RealColumn get amount => real()();
  TextColumn get payDate => text().map(const DateOnlyConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {symbol, exDate};
}

@DataClassName('SplitRow')
class SplitEventsCache extends Table {
  TextColumn get symbol => text()();
  TextColumn get date => text().map(const DateOnlyConverter())();
  IntColumn get numerator => integer()();
  IntColumn get denominator => integer()();

  @override
  Set<Column<Object>> get primaryKey => {symbol, date};
}

@DataClassName('ImportMappingRow')
class ImportMappings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get mappingJson => text()();
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('LunoConnectionRow')
class LunoConnections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  IntColumn get portfolioId => integer().references(Portfolios, #id, onDelete: KeyAction.cascade)();

  /// Last 4 characters of the API key id. The key id and secret live only in the secure store.
  TextColumn get keyIdHint => text().withDefault(const Constant(''))();
  TextColumn get homeFiat => text()();

  /// `ok` | `syncing` | `error` | `revoked` | `credentials_missing` | `needs_review`.
  TextColumn get status => text().withDefault(const Constant('credentials_missing'))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  BoolColumn get writePermWarning => boolean().withDefault(const Constant(false))();
  IntColumn get unrecognisedRows => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('LunoCursorRow')
class LunoAccountCursors extends Table {
  IntColumn get connectionId => integer().references(LunoConnections, #id, onDelete: KeyAction.cascade)();
  TextColumn get accountId => text()();
  TextColumn get asset => text()();
  TextColumn get accountType => text().withDefault(const Constant(''))();
  IntColumn get lastRowIndex => integer().withDefault(const Constant(0))();
  TextColumn get balanceSnapshot => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  TextColumn get reservedSnapshot => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  TextColumn get unconfirmedSnapshot => text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {connectionId, accountId};
}

@DataClassName('LunoMarketRow')
class LunoMarketsCache extends Table {
  TextColumn get pair => text()();
  TextColumn get base => text()();
  TextColumn get counter => text()();
  IntColumn get priceScale => integer().withDefault(const Constant(0))();
  IntColumn get volumeScale => integer().withDefault(const Constant(0))();
  TextColumn get tradingStatus => text().withDefault(const Constant('UNKNOWN'))();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {pair};
}

/// Raw ledger rows fetched from Luno, kept until they have been mapped to transactions. Staging makes the first
/// sync resumable page by page and lets rows be paired across accounts (the two legs of a trade live in different
/// accounts) and re-mapped when the mapping improves. Derived data: excluded from backups.
@DataClassName('LunoLedgerRow')
class LunoLedgerRows extends Table {
  IntColumn get connectionId => integer().references(LunoConnections, #id, onDelete: KeyAction.cascade)();
  TextColumn get accountId => text()();
  IntColumn get rowIndex => integer()();
  IntColumn get timestampMs => integer()();

  /// The row as returned by the API (JSON), with ledger numbers quoted so decimals survive.
  TextColumn get payloadJson => text()();

  /// `pending` (not yet mapped, or waiting for its counterpart) | `mapped` | `unrecognised`.
  TextColumn get state => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {connectionId, accountId, rowIndex};
}
