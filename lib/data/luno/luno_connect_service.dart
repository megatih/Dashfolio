import 'package:dio/dio.dart';

import '../../core/failure.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/luno.dart';
import '../../domain/repositories/luno_repository.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../net/request_scheduler.dart';
import 'luno_client.dart';
import 'luno_credential_store.dart';
import 'luno_permission_probe.dart';

/// Creates, re-keys and removes Luno connections. All credential handling is here and goes through the secure store;
/// nothing about a key is persisted anywhere else except the last four characters of its id.
class LunoConnectService {
  LunoConnectService({required this.store, required this.luno, required this.portfolios, required this.dio, this.scheduler});

  final LunoCredentialStore store;
  final LunoRepository luno;
  final PortfolioRepository portfolios;
  final Dio dio;
  final RequestScheduler? scheduler;

  LunoClient _client(LunoCredentials credentials) => LunoClient(dio: dio, scheduler: scheduler, credentials: () async => credentials);

  /// Validates [credentials] and reports what the key can do. Throws the usual typed failures (revoked, network...).
  Future<LunoKeyCheck> verify(LunoCredentials credentials) => LunoPermissionProbe(_client(credentials)).check();

  /// The fiat wallet most likely to be the user's home currency: the largest non-empty one, else the first.
  static String suggestHomeFiat(Iterable<LunoAccount> accounts, {String fallback = 'USD'}) {
    final fiat = accounts.where((a) => isLunoFiat(a.asset)).toList();
    if (fiat.isEmpty) return isLunoFiat(fallback) ? fallback : 'USD';
    fiat.sort((a, b) => b.total.compareTo(a.total));
    return fiat.first.asset;
  }

  /// Creates the synced portfolio and the connection, and stores the credentials. Nothing is left behind on failure.
  ///
  /// [sendPermissionConfirmedAbsent] is the user's attestation that the key lacks "Send to any address", which cannot be
  /// verified without moving money; without it the connection keeps a visible warning.
  Future<int> connect({
    required LunoCredentials credentials,
    required LunoKeyCheck check,
    required String label,
    required String homeFiat,
    required CostMethod costMethod,
    bool sendPermissionConfirmedAbsent = false,
  }) async {
    if (!check.acceptable) throw const UnsafeKeyFailure();
    if (!await store.isAvailable()) throw const SecureStorageUnavailableFailure();
    final name = label.trim().isEmpty ? 'Luno' : label.trim();

    final portfolioId = await portfolios.createPortfolio(
      NewPortfolio(
        name: 'Luno – $name',
        description: 'Synced from Luno. Read-only: changes are made in Luno.',
        color: 0xFFF59E0B,
        costMethod: costMethod,
      ),
    );
    int? connectionId;
    try {
      // Credentials first, status last: a sync can never see an "ok" connection without a key.
      connectionId = await luno.createConnection(
        label: name,
        portfolioId: portfolioId,
        keyIdHint: credentials.keyIdHint,
        homeFiat: homeFiat,
        writePermWarning: !sendPermissionConfirmedAbsent,
      );
      await store.write(connectionId, credentials);
      await luno.setStatus(connectionId, LunoConnectionStatus.ok);
      return connectionId;
    } on Object {
      if (connectionId != null) {
        try {
          await store.delete(connectionId);
        } on Object {
          // Nothing more can be done; the connection row is removed below so the key is unreachable by the app.
        }
      }
      await portfolios.deletePortfolio(portfolioId); // cascades the connection
      rethrow;
    }
  }

  /// Replaces the key of an existing connection (e.g. after revocation). The new key must belong to the same Luno user.
  Future<void> replaceKey({required int connectionId, required LunoCredentials credentials, required LunoKeyCheck check}) async {
    if (!check.acceptable) throw const UnsafeKeyFailure();
    final known = (await luno.getCursors(connectionId)).keys.toSet();
    if (known.isNotEmpty && check.accounts.every((a) => !known.contains(a.accountId))) throw const KeyMismatchFailure();
    final conn = await luno.getConnection(connectionId);
    if (conn == null) throw const NotFoundFailure('Connection not found');
    await store.write(connectionId, credentials);
    await luno.updateConnection(conn.copyWith(keyIdHint: credentials.keyIdHint));
    await luno.setStatus(connectionId, LunoConnectionStatus.ok);
  }

  /// Wipes the secret immediately, then either keeps the synced data as an ordinary editable portfolio or deletes it.
  /// If the secret cannot be removed nothing else changes, so the user can retry.
  Future<void> disconnect(int connectionId, {required bool keepPortfolio}) async {
    final conn = await luno.getConnection(connectionId);
    await store.delete(connectionId);
    if (conn == null) return;
    if (keepPortfolio) {
      await luno.detachSyncedTransactions(connectionId);
      await luno.deleteConnection(connectionId);
    } else {
      await portfolios.deletePortfolio(conn.portfolioId); // cascades connection, cursors, staged rows and transactions
    }
  }

  /// Removes every connection (turning the app lock off, resetting the app). Portfolios are kept or deleted as asked.
  Future<void> disconnectAll({required bool keepPortfolios}) async {
    final connections = await luno.getConnections();
    for (final c in connections) {
      await disconnect(c.id, keepPortfolio: keepPortfolios);
    }
    try {
      await store.deleteAll(); // strays: keys of connections that no longer exist
    } on SecureStorageUnavailableFailure {
      // No secure store means no secrets either (e.g. Linux without a keyring); that must not block turning the lock off.
      if (connections.isNotEmpty) rethrow;
    }
  }
}
