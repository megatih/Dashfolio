import 'dart:math';

import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/luno/luno_client.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:dashfolio/data/luno/luno_permission_probe.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';
import '../../support/luno_fixtures.dart';

/// A key described by which reads it may do and how the two write probes are answered.
FakeAdapter keyAdapter({
  bool readTransactions = true,
  bool readOrders = true,
  bool readTransfers = true,
  bool readWithdrawals = true,
  ResponseBody Function()? stopOrder,
  ResponseBody Function()? cancelWithdrawal,
}) {
  ResponseBody forbidden() => jsonBody(lunoFixtureText('error_perms.json'), 403);
  return FakeAdapter((o) {
    final path = o.uri.path;
    if (o.method == 'POST' && path == '/api/1/stoporder') return (stopOrder ?? forbidden)();
    if (o.method == 'DELETE' && path.startsWith('/api/1/withdrawals/')) return (cancelWithdrawal ?? forbidden)();
    if (path == '/api/1/balance') return jsonBody(lunoFixtureText('balance.json'));
    if (path.endsWith('/transactions')) return readTransactions ? jsonBody(lunoFixtureText('ledger_empty.json')) : forbidden();
    if (path == '/api/1/listtrades') return readOrders ? jsonBody('{"trades":[]}') : forbidden();
    if (path == '/api/exchange/1/transfers') return readTransfers ? jsonBody('{"transfers":[]}') : forbidden();
    if (path == '/api/1/withdrawals') return readWithdrawals ? jsonBody('{"withdrawals":[]}') : forbidden();
    return jsonBody('{}', 404);
  });
}

LunoPermissionProbe probe(FakeAdapter a) => LunoPermissionProbe(
  LunoClient(
    dio: Dio()..httpClientAdapter = a,
    credentials: () async => const LunoCredentials(keyId: 'k', keySecret: 's'),
    maxAttempts: 1,
    backoff: (_) async {},
  ),
  random: Random(7),
);

ResponseBody orderNotFound() => jsonBody(lunoFixtureText('error_order_not_found.json'), 400);
ResponseBody withdrawalNotFound() => jsonBody(lunoFixtureText('error_withdrawal_not_found.json'), 404);

void main() {
  test('a key without write permissions is acceptable', () async {
    final check = await probe(keyAdapter()).check();
    expect(check.acceptable, isTrue);
    expect(check.writeOrders, LunoPermissionState.absent);
    expect(check.writeWithdrawals, LunoPermissionState.absent);
    expect(check.hasRequiredReads, isTrue);
    expect(check.accounts.length, 3);
  });

  test('write probes use only a fake order id and withdrawal id 0, as form data', () async {
    final a = keyAdapter();
    await probe(a).check();
    final writes = a.requests.where((r) => r.method != 'GET').toList();
    expect(writes.map((r) => '${r.method} ${r.uri.path}'), ['POST /api/1/stoporder', 'DELETE /api/1/withdrawals/0']);
    final orderId = (writes.first.data as Map)['order_id'] as String;
    expect(orderId, matches(RegExp(r'^BX[A-Z2-9]{13}$')));
    expect(a.requests.any((r) => r.uri.path.contains('send')), isFalse);
    expect(a.requests.where((r) => r.method == 'GET').length, 5);
  });

  test('a key that can stop orders is rejected', () async {
    final check = await probe(keyAdapter(stopOrder: orderNotFound)).check();
    expect(check.writeOrders, LunoPermissionState.present);
    expect(check.hasDangerousWrites, isTrue);
    expect(check.acceptable, isFalse);
  });

  test('a key that can cancel withdrawals is rejected', () async {
    final check = await probe(keyAdapter(cancelWithdrawal: withdrawalNotFound)).check();
    expect(check.writeWithdrawals, LunoPermissionState.present);
    expect(check.acceptable, isFalse);
  });

  test('an unrecognised answer to a write probe is inconclusive, not a pass', () async {
    final check = await probe(keyAdapter(stopOrder: () => jsonBody('{"code":"ErrSomethingNew","message":"?"}', 400))).check();
    expect(check.writeOrders, LunoPermissionState.unknown);
    expect(check.inconclusive, isTrue);
    expect(check.acceptable, isFalse);
  });

  test('missing required read permissions fail the key; optional ones do not', () async {
    expect((await probe(keyAdapter(readOrders: false)).check()).acceptable, isFalse);
    expect((await probe(keyAdapter(readTransactions: false)).check()).acceptable, isFalse);
    final optional = await probe(keyAdapter(readTransfers: false, readWithdrawals: false)).check();
    expect(optional.acceptable, isTrue);
    expect((optional.readTransfers, optional.readWithdrawals), (false, false));
  });

  test('a key without balance permission stops early and probes nothing', () async {
    final a = FakeAdapter((o) => jsonBody(lunoFixtureText('error_perms.json'), 403));
    final check = await probe(a).check();
    expect(check.readBalance, isFalse);
    expect(check.acceptable, isFalse);
    expect(a.requests.length, 1);
  });

  test('a revoked key and an unreachable API surface as failures rather than a verdict', () async {
    await expectLater(
      probe(FakeAdapter((o) => jsonBody(lunoFixtureText('error_revoked.json'), 401))).check(),
      throwsA(isA<KeyRevokedFailure>()),
    );
    final down = keyAdapter();
    final inner = down.handler;
    down.handler = (o) => o.uri.path == '/api/1/listtrades' ? jsonBody('{}', 503) : inner(o);
    await expectLater(probe(down).check(), throwsA(isA<NetworkFailure>()));
  });

  test('the send permission can never be verified, so the warning is unconditional', () {
    expect(LunoKeyCheck.sendPermissionUnverifiable, isTrue);
  });

  test('diagnostics list what Luno answered to every check, without credentials or account ids', () async {
    final check = await probe(keyAdapter()).check();
    expect(check.diagnostics, [
      'GET /api/1/accounts/{id}/transactions → 200',
      'GET /api/1/listtrades → 200',
      'GET /api/exchange/1/transfers → 200',
      'GET /api/1/withdrawals → 200',
      'POST /api/1/stoporder → 403 ErrInsufficientPerms',
      'DELETE /api/1/withdrawals/0 → 403 ErrInsufficientPerms',
    ]);
    final all = check.diagnostics.join();
    expect(all, isNot(contains('1001')));
    expect(all, isNot(contains('BX')));
  });

  test('a risky key shows the answer that gave it away', () async {
    final check = await probe(keyAdapter(stopOrder: orderNotFound)).check();
    expect(check.diagnostics.any((l) => l.startsWith('POST /api/1/stoporder → 400 ErrCannotStopUnknownOrNonPendingOrder')), isTrue);
  });

  test('real Luno answers a write probe from a read-only key with a bare 403 and no error code: still "absent"', () async {
    // Recorded with tool/check_luno_key.dart against a live read-only key.
    final bare = keyAdapter(stopOrder: () => jsonBody('', 403), cancelWithdrawal: () => jsonBody('', 403));
    final check = await probe(bare).check();
    expect(check.writeOrders, LunoPermissionState.absent);
    expect(check.writeWithdrawals, LunoPermissionState.absent);
    expect(check.acceptable, isTrue);
    expect(check.diagnostics.where((l) => l.contains('→ 403')).length, 2);
    expect(check.diagnostics.any((l) => l.contains('ErrInsufficientPerms')), isFalse);
  });
}
