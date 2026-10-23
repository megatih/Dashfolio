// Checks a Luno API key exactly the way the app's connect wizard does (same code), and prints what Luno answered.
//
//   LUNO_KEY_ID=... LUNO_KEY_SECRET=... dart run tool/check_luno_key.dart
//
// What it sends: GET /balance, then one-row reads of the ledger, trades, transfers and withdrawals to see which view
// permissions the key has, and the two write probes the app uses, which can only fail for a read-only key:
// a stop on an order id that cannot exist, and a cancel of withdrawal 0. It never calls /send or any endpoint that moves
// money, and it never prints the key or secret. Use it to confirm how Luno answers the probes for your key.
import 'dart:io';

import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/luno/luno_client.dart';
import 'package:dashfolio/data/luno/luno_credentials.dart';
import 'package:dashfolio/data/luno/luno_permission_probe.dart';
import 'package:dio/dio.dart';

Future<void> main() async {
  final id = Platform.environment['LUNO_KEY_ID'];
  final secret = Platform.environment['LUNO_KEY_SECRET'];
  if (id == null || secret == null || id.isEmpty || secret.isEmpty) {
    stderr.writeln('Set LUNO_KEY_ID and LUNO_KEY_SECRET in the environment.');
    exit(64);
  }
  final creds = LunoCredentials(keyId: id, keySecret: secret);
  final client = LunoClient(dio: Dio(), credentials: () async => creds);
  try {
    final check = await LunoPermissionProbe(client).check();
    stdout.writeln('Wallets: ${check.accounts.length}');
    String yes(bool b) => b ? 'yes' : 'NO';
    stdout.writeln('View balance      ${yes(check.readBalance)}');
    stdout.writeln('View transactions ${yes(check.readTransactions)}');
    stdout.writeln('View orders       ${yes(check.readOrders)}');
    stdout.writeln('View transfers    ${yes(check.readTransfers)} (optional)');
    stdout.writeln('View withdrawals  ${yes(check.readWithdrawals)} (optional)');
    stdout.writeln('Create/stop orders         ${check.writeOrders.name}');
    stdout.writeln('Request/cancel withdrawals ${check.writeWithdrawals.name}');
    stdout.writeln('\nWhat Luno answered:');
    for (final line in check.diagnostics) {
      stdout.writeln('  $line');
    }
    stdout.writeln('\nVerdict: ${check.acceptable ? 'ACCEPTED (read-only as far as can be tested)' : 'REFUSED'}');
    if (check.hasDangerousWrites) stdout.writeln('  The key can place orders or withdraw funds.');
    if (!check.hasRequiredReads) stdout.writeln('  The key lacks a view permission the app needs.');
    if (check.inconclusive) stdout.writeln('  A probe answer was not understood. Please share the lines above (they contain no secrets).');
    stdout.writeln('\nNote: "Send to any address" cannot be tested without moving money; check it in Luno yourself.');
  } on AppFailure catch (f) {
    stderr.writeln('Could not complete the check: ${f.message}');
    exit(1);
  }
  exit(0);
}
