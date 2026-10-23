import '../entities/luno.dart';
import '../entities/portfolio.dart';

/// A ledger row held in the local staging area until it is mapped to a transaction.
class LunoStagedRow {
  const LunoStagedRow({
    required this.accountId,
    required this.rowIndex,
    required this.timestamp,
    required this.payloadJson,
    this.state = 'pending',
  });

  final String accountId;
  final int rowIndex;
  final DateTime timestamp;

  /// The API row as JSON (ledger numbers quoted so decimals survive).
  final String payloadJson;

  /// `pending` | `mapped` | `unrecognised`.
  final String state;

  String get key => '$accountId:$rowIndex';
}

/// Persistence for Luno connections and their sync state. Credentials are *not* stored here (see the credential store).
abstract class LunoRepository {
  Stream<List<LunoConnection>> watchConnections();
  Future<List<LunoConnection>> getConnections();
  Future<LunoConnection?> getConnection(int id);

  Future<int> createConnection({
    required String label,
    required int portfolioId,
    required String keyIdHint,
    required String homeFiat,
    LunoConnectionStatus status = LunoConnectionStatus.credentialsMissing,
    bool writePermWarning = false,
  });

  /// Updates label, home fiat, key hint and the permission warning.
  Future<void> updateConnection(LunoConnection c);

  /// Records the outcome of a sync attempt. [error] is cleared when null.
  Future<void> setStatus(int id, LunoConnectionStatus status, {String? error, DateTime? lastSyncAt, int? unrecognisedRows});

  /// Removes the connection with its cursors and staged rows. Callers first detach or delete its synced transactions
  /// (otherwise they stay behind as read-only rows without a connection).
  Future<void> deleteConnection(int id);

  // ---- sync state ----------------------------------------------------------

  Future<Map<String, LunoAccountCursor>> getCursors(int connectionId);
  Future<void> upsertCursor(LunoAccountCursor cursor);

  /// Inserts rows not yet staged (existing rows are left untouched). Returns how many were new.
  Future<int> stageRows(int connectionId, List<LunoStagedRow> rows);

  Future<List<LunoStagedRow>> stagedRows(int connectionId, {Set<String> states = const {'pending', 'unrecognised'}});
  Future<void> setRowStates(int connectionId, Map<String, String> stateByKey);

  /// Marks every staged row pending again so the next sync re-maps all of them. Cursors are untouched: nothing is refetched.
  Future<void> resetStagedStates(int connectionId);

  // ---- synced transactions -------------------------------------------------

  Future<List<PortfolioTransaction>> syncedTransactions(int connectionId);

  /// Inserts new transactions and updates existing ones (matched by external id) without touching user notes.
  Future<void> upsertSyncedTransactions(int connectionId, List<PortfolioTransaction> txs);

  /// Turns the connection's synced transactions into ordinary editable ones ("keep as manual portfolio").
  Future<void> detachSyncedTransactions(int connectionId);

  /// Deletes the connection's synced transactions (used by a full re-map).
  Future<int> deleteSyncedTransactions(int connectionId);
}
