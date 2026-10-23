import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Read-only by construction: the only code that may send anything but GET is the permission probe.
void main() {
  final files = Directory('lib/data/luno').listSync().whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  // HTTP-verb strings, or dio's verb helpers (not keychain `store.delete(...)` calls).
  final nonGet = RegExp(r'''['"](POST|PUT|PATCH|DELETE)['"]|\b_?dio\.(post|put|patch|delete)(<[^>]*>)?\(''');

  test('only the permission probe names a non-GET HTTP method', () {
    // Files that do not talk HTTP (e.g. the credential store deletes keychain entries) are out of scope.
    final http = files.where((f) => f.readAsStringSync().contains("package:dio/dio.dart") || f.path.endsWith('luno_permission_probe.dart'));
    for (final f in http) {
      final name = f.uri.pathSegments.last;
      final hits = nonGet.allMatches(f.readAsStringSync()).map((m) => m.group(0)).toList();
      if (name == 'luno_permission_probe.dart') {
        expect(hits.toSet(), {"'POST'", "'DELETE'"}, reason: 'the probe must use exactly POST /stoporder and DELETE /withdrawals/0');
      } else {
        expect(hits, isEmpty, reason: '$name must not send non-GET requests');
      }
    }
  });

  test('rawRequest is only called by the permission probe', () {
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      if (name == 'luno_client.dart' || name == 'luno_permission_probe.dart') continue;
      expect(f.readAsStringSync(), isNot(contains('rawRequest(')), reason: name);
    }
  });

  test('no money-moving or account-changing endpoint is referenced anywhere in the Luno layer', () {
    const forbidden = [
      '/send',
      '/postorder',
      '/marketorder',
      '/funding_address',
      '/beneficiaries',
      '/convert',
      '/move',
      'address/validate',
      '/accounts/name',
    ];
    for (final f in files) {
      final src = f.readAsStringSync();
      for (final p in forbidden) {
        expect(src, isNot(contains("'/api/1$p")), reason: '${f.path} references $p');
        expect(src, isNot(contains("'/api/exchange/1$p")), reason: '${f.path} references $p');
      }
    }
    // The one write endpoint the probe uses is a stop of a non-existent order, and a cancel of withdrawal 0.
    final probe = File('lib/data/luno/luno_permission_probe.dart').readAsStringSync();
    expect(RegExp(r"'(/api/[^']*)'").allMatches(probe).map((m) => m.group(1)).where((p) => !p!.contains('transactions')).toSet(), {
      '/api/1/listtrades',
      '/api/exchange/1/transfers',
      '/api/1/withdrawals',
      '/api/1/stoporder',
      '/api/1/withdrawals/0',
    });
  });
}
