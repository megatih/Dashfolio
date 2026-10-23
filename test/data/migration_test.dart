import 'package:drift/drift.dart' show OrderingTerm, QueryExecutorUser, QueryExecutor, OpeningDetails;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashfolio/data/db/app_database.dart';

import '../generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('fresh database matches the dumped v2 schema', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('v1 migrates to v2 with the same schema as a fresh v2 database', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('v1 data survives and CSV-imported rows are backfilled with source = csv', () async {
    final schema = await verifier.schemaAt(1);
    final raw = schema.newConnection();
    await raw.ensureOpen(_NoopUser());
    await raw.runCustom(
      "INSERT INTO portfolios (name, color, cost_basis_method, sort_order, archived, created_at) VALUES ('P', 1, 'average', 0, 0, 0)",
    );
    const cols = 'portfolio_id, symbol, type, trade_date, quantity, price, fees, currency, fx_rate_to_base, import_batch_id, created_at';
    await raw.runCustom("INSERT INTO transactions ($cols) VALUES (1, 'AAPL', 'buy', '2024-01-02', '1', '10', '0', 'USD', '1', NULL, 0)");
    await raw.runCustom(
      "INSERT INTO transactions ($cols) VALUES (1, 'AAPL', 'buy', '2024-01-03', '1', '11', '0', 'USD', '1', 'batch1', 0)",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    final rows = await (db.select(db.transactions)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(rows.map((r) => r.source), ['manual', 'csv']);
    expect(rows.every((r) => r.connectionId == null && r.externalId == null && r.executedAt == null), isTrue);
  });

  test('creates all tables on a new in-memory database', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await db.select(db.portfolios).get(), isEmpty);
    expect(await db.select(db.lunoConnections).get(), isEmpty);
  });
}

class _NoopUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 1;
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}
