import 'dart:math';

import '../../core/failure.dart';
import '../../domain/entities/luno.dart';
import '../net/request_scheduler.dart';
import 'luno_client.dart';

enum LunoPermissionState { absent, present, unknown }

/// What a key can do, as far as it can be learned without side effects.
class LunoKeyCheck {
  const LunoKeyCheck({
    required this.readBalance,
    required this.readTransactions,
    required this.readOrders,
    required this.readTransfers,
    required this.readWithdrawals,
    required this.writeOrders,
    required this.writeWithdrawals,
    this.accounts = const [],
    this.diagnostics = const [],
  });

  final bool readBalance;
  final bool readTransactions;
  final bool readOrders;

  /// Optional: without it the sync cannot link on-chain transaction ids and network fees.
  final bool readTransfers;

  /// Optional: only used to show withdrawal status.
  final bool readWithdrawals;

  /// Create/stop orders (`Perm_W_Orders`).
  final LunoPermissionState writeOrders;

  /// Request/cancel withdrawals (`Perm_W_Withdrawals`).
  final LunoPermissionState writeWithdrawals;

  /// Accounts seen while validating the key.
  final List<LunoAccount> accounts;

  /// What Luno answered to each check, e.g. `POST /api/1/stoporder → 403 ErrInsufficientPerms`. No credentials or ids.
  final List<String> diagnostics;

  bool get hasRequiredReads => readBalance && readTransactions && readOrders;

  /// A write permission was positively detected: the key must be rejected.
  bool get hasDangerousWrites => writeOrders == LunoPermissionState.present || writeWithdrawals == LunoPermissionState.present;

  /// A write probe could not be classified; do not proceed on a guess.
  bool get inconclusive => writeOrders == LunoPermissionState.unknown || writeWithdrawals == LunoPermissionState.unknown;

  bool get acceptable => hasRequiredReads && !hasDangerousWrites && !inconclusive;

  /// `Perm_W_Send` cannot be probed safely (a send would move money), so every key gets this warning: Luno's
  /// "Read-only access" preset includes "Send to any address".
  static const sendPermissionUnverifiable = true;
}

/// Checks a key's permissions with calls that cannot change anything.
///
/// Write permissions are detected by invoking a write endpoint with an id that cannot exist: a key without the
/// permission is refused (403 / `ErrInsufficientPerms`) before the id is looked up, whereas a key with it gets a
/// "not found" error. This is the only code in the app that sends a non-GET request, and `/send` is never touched.
class LunoPermissionProbe {
  LunoPermissionProbe(this._client, {Random? random}) : _random = random ?? Random.secure();

  final LunoClient _client;
  final Random _random;

  static const _orderNotFoundCodes = {'ErrCannotStopUnknownOrNonPendingOrder', 'ErrOrderNotFound', 'ErrInvalidOrderRef'};
  static const _withdrawalNotFoundCodes = {'ErrWithdrawalNotFound', 'ErrNotFound'};
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _fakeOrderId() => 'BX${List.generate(13, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join()}';

  /// Reads are allowed unless the key is refused; a 4xx about the arguments means the permission check passed.
  final _log = <String>[];

  Future<LunoRawResponse> _send(String method, String path, {Map<String, Object> query = const {}, Map<String, String>? form}) async {
    final r = await _client.rawRequest(method, path, query: query, form: form);
    // Paths with an account id in them are reduced to their shape; the answer is what matters.
    final shape = path.replaceAllMapped(RegExp(r'/accounts/[^/]+/'), (_) => '/accounts/{id}/');
    _log.add('$method $shape → ${r.status}${r.code.isEmpty ? '' : ' ${r.code}'}');
    return r;
  }

  bool _readAllowed(LunoRawResponse r) {
    if (r.status == 401) throw const KeyRevokedFailure();
    if (r.status == 429 || r.status >= 500) throw lunoFailureFor(r);
    return !(r.status == 403 || r.code == 'ErrInsufficientPerms');
  }

  LunoPermissionState _writeState(LunoRawResponse r, Set<String> notFoundCodes) {
    if (r.status == 401) throw const KeyRevokedFailure();
    if (r.status == 403 || r.code == 'ErrInsufficientPerms') return LunoPermissionState.absent;
    if (r.status == 200 || r.status == 404 || notFoundCodes.contains(r.code)) return LunoPermissionState.present;
    return LunoPermissionState.unknown;
  }

  /// Throws the usual typed failures for a rejected (401), rate-limited or unreachable API.
  Future<LunoKeyCheck> check() async {
    _log.clear();
    final List<LunoAccount> accounts;
    try {
      accounts = await _client.balances(priority: RequestPriority.user);
    } on ForbiddenFailure {
      return const LunoKeyCheck(
        readBalance: false,
        readTransactions: false,
        readOrders: false,
        readTransfers: false,
        readWithdrawals: false,
        writeOrders: LunoPermissionState.unknown,
        writeWithdrawals: LunoPermissionState.unknown,
      );
    }

    final account = accounts.firstOrNull;
    final fiat = accounts.where((a) => isLunoFiat(a.asset)).firstOrNull?.asset;
    final crypto = accounts.where((a) => !isLunoFiat(a.asset)).firstOrNull?.asset;
    final pair = '${crypto ?? 'XBT'}${fiat ?? 'ZAR'}';

    // Latest ledger row only (negative rows wrap to the most recent).
    final tx = account == null
        ? true
        : _readAllowed(
            await _send(
              'GET',
              '/api/1/accounts/${Uri.encodeComponent(account.accountId)}/transactions',
              query: {'min_row': '-1', 'max_row': '0'},
            ),
          );
    final orders = _readAllowed(await _send('GET', '/api/1/listtrades', query: {'pair': pair, 'limit': '1'}));
    final transfers = account == null
        ? true
        : _readAllowed(await _send('GET', '/api/exchange/1/transfers', query: {'account_id': account.accountId, 'limit': '1'}));
    final withdrawals = _readAllowed(await _send('GET', '/api/1/withdrawals', query: {'limit': '1'}));

    final stop = await _send('POST', '/api/1/stoporder', form: {'order_id': _fakeOrderId()});
    final cancel = await _send('DELETE', '/api/1/withdrawals/0');

    return LunoKeyCheck(
      readBalance: true,
      readTransactions: tx,
      readOrders: orders,
      readTransfers: transfers,
      readWithdrawals: withdrawals,
      writeOrders: _writeState(stop, _orderNotFoundCodes),
      writeWithdrawals: _writeState(cancel, _withdrawalNotFoundCodes),
      accounts: accounts,
      diagnostics: List.unmodifiable(_log),
    );
  }
}

AppFailure lunoFailureFor(LunoRawResponse r) =>
    r.status == 429 ? const RateLimitedFailure('Luno is rate limiting requests') : const NetworkFailure('Luno is temporarily unavailable');
