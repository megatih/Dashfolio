// ignore_for_file: unused_import
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Portfolios,
    Instruments,
    Transactions,
    Watchlists,
    WatchlistItems,
    QuoteCache,
    ProfileCache,
    PriceHistoryCache,
    HistoryMeta,
    DividendEventsCache,
    SplitEventsCache,
    ImportMappings,
    Settings,
    LunoConnections,
    LunoAccountCursors,
    LunoMarketsCache,
    LunoLedgerRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'dashfolio',
              web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
            ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2 (Luno): the connections table must exist before transactions reference it.
        await m.createTable(lunoConnections);
        await m.createTable(lunoAccountCursors);
        await m.createTable(lunoMarketsCache);
        await m.createTable(lunoLedgerRows);
        await m.addColumn(transactions, transactions.source);
        await m.addColumn(transactions, transactions.connectionId);
        await m.addColumn(transactions, transactions.externalId);
        await m.addColumn(transactions, transactions.executedAt);
        await m.createIndex(transactionsConnectionExternal);
        await customStatement("UPDATE transactions SET source = 'csv' WHERE import_batch_id IS NOT NULL");
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
