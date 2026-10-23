import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'fake_http.dart';
import 'luno_fixtures.dart';

/// An in-memory Luno: serves the fixture account, paging ledgers like the real API, and records every request.
class FakeLunoServer {
  /// [dir] is a sub-directory of `test/fixtures/luno` (e.g. `live`); by default the small synthetic MYR account.
  FakeLunoServer({String dir = ''}) {
    final prefix = dir.isEmpty ? '' : '$dir/';
    final files =
        dir.isEmpty
              ? ['ledger_myr.json', 'ledger_xbt.json', 'ledger_eth.json']
              : [
                  for (final f in Directory('test/fixtures/luno/$dir').listSync().whereType<File>())
                    if (f.uri.pathSegments.last.startsWith('ledger_')) f.uri.pathSegments.last,
                ]
          ..sort();
    for (final f in files) {
      final j = rawJson('$prefix$f')! as Map<String, Object?>;
      ledgers['${j['id']}'] = [...(j['transactions']! as List).cast<Map<String, Object?>>()];
    }
    balances = [...((rawJson('${prefix}balance.json')! as Map<String, Object?>)['balance']! as List).cast<Map<String, Object?>>()];
    adapter = FakeAdapter(_handle);
  }

  late final FakeAdapter adapter;
  final Map<String, List<Map<String, Object?>>> ledgers = {};
  late List<Map<String, Object?>> balances;

  /// Paths (e.g. `/api/1/accounts/1002/transactions`) answered with this status instead of the data.
  final Map<String, int> failing = {};
  int? balanceStatus;
  bool revoked = false;

  /// What the API key may do. Read-only by default; flip these to model riskier keys.
  bool canReadTransactions = true;
  bool canReadOrders = true;
  bool canStopOrders = false;
  bool canCancelWithdrawals = false;

  /// Answers to the write probes when a permission is present or absent.
  int? stopOrderOverride;

  List<RequestOptions> get requests => adapter.requests;
  Iterable<RequestOptions> get ledgerRequests => requests.where((r) => r.uri.path.endsWith('/transactions'));

  Map<String, Object?> balanceOf(String asset) => balances.firstWhere((b) => b['asset'] == asset);

  void setBalance(String asset, {String? balance, String? reserved}) {
    final b = balanceOf(asset);
    if (balance != null) b['balance'] = balance;
    if (reserved != null) b['reserved'] = reserved;
  }

  ResponseBody _handle(RequestOptions o) {
    if (revoked) return jsonBody(lunoFixtureText('error_revoked.json'), 401);
    final status = failing[o.uri.path];
    if (status != null) return jsonBody(lunoFixtureText('error_unavailable.json'), status);
    final path = o.uri.path;
    ResponseBody perms() => jsonBody(lunoFixtureText('error_perms.json'), 403);
    if (o.method == 'POST' && path == '/api/1/stoporder') {
      if (stopOrderOverride != null) return jsonBody('{"code":"ErrSomethingNew"}', stopOrderOverride!);
      return canStopOrders ? jsonBody(lunoFixtureText('error_order_not_found.json'), 400) : perms();
    }
    if (o.method == 'DELETE' && path.startsWith('/api/1/withdrawals/')) {
      return canCancelWithdrawals ? jsonBody(lunoFixtureText('error_withdrawal_not_found.json'), 404) : perms();
    }
    if (path == '/api/1/listtrades') return canReadOrders ? jsonBody('{"trades":[]}') : perms();
    if (path == '/api/exchange/1/transfers') return jsonBody('{"transfers":[]}');
    if (path == '/api/1/withdrawals') return jsonBody('{"withdrawals":[]}');
    if (path == '/api/1/balance') {
      return balanceStatus != null ? jsonBody('{}', balanceStatus!) : jsonBody(jsonEncode({'balance': balances}));
    }
    final m = RegExp(r'^/api/1/accounts/([^/]+)/transactions$').firstMatch(path);
    if (m != null) {
      if (!canReadTransactions) return perms();
      final id = m.group(1)!;
      final min = int.parse(o.queryParameters['min_row'] as String);
      final max = int.parse(o.queryParameters['max_row'] as String);
      final rows = (ledgers[id] ?? const <Map<String, Object?>>[])
          .where((r) => (r['row_index']! as int) >= min && (r['row_index']! as int) < max)
          .toList();
      return jsonBody(jsonEncode({'id': id, 'transactions': rows}));
    }
    return jsonBody('{}', 404);
  }
}
