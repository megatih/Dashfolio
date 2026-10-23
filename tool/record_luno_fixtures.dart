// Records scrubbed Luno API responses into test/fixtures/luno/ using a READ-ONLY key.
//
//   LUNO_KEY_ID=... LUNO_KEY_SECRET=... dart run tool/record_luno_fixtures.dart [--out test/fixtures/luno/live]
//   dart run tool/record_luno_fixtures.dart --rescrub test/fixtures/luno/live   # re-apply the scrubbing rules to existing files
//
// Only GET requests are sent. The key is read from the environment (never from arguments or files) and is never
// written anywhere. Before anything is saved, account/order/trade/transfer ids, references, on-chain hashes and
// addresses are replaced by deterministic placeholders, free-text details are blanked, and every amount is multiplied
// by LUNO_SCRUB_FACTOR (default 0.37; prices are left alone so price * volume relations stay plausible).
// Review the output before committing it.
import 'dart:convert';
import 'dart:io';

import 'package:dashfolio/data/luno/luno_mappers.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

const _amountKeys = {
  'balance',
  'reserved',
  'unconfirmed',
  'balance_delta',
  'available',
  'available_delta',
  'base',
  'counter',
  'fee_base',
  'fee_counter',
  'volume',
  'amount',
  'fee',
  'rolling_24_hour_volume',
  'thirty_day_volume',
};
const _ledgerNumberKeys = {'balance', 'balance_delta', 'available', 'available_delta'};

class Scrubber {
  Scrubber(this.factor);
  final Decimal factor;
  final _ids = <String, Map<String, String>>{};

  String _map(String kind, String value, String Function(int n) make) {
    final m = _ids.putIfAbsent(kind, () => {});
    return m.putIfAbsent(value, () => make(m.length + 1));
  }

  /// [idKind] says what a bare `id` field identifies in this document (`account` for ledgers, `transfer` for transfers).
  Object? scrub(Object? v, [String? key, String idKind = 'account']) {
    if (v is Map<String, Object?> && key == 'details') return {for (final e in v.entries) e.key: _detail(e.value)};
    if (v is Map<String, Object?>) return {for (final e in v.entries) e.key: scrub(e.value, e.key, idKind)};
    if (v is List) return [for (final x in v) scrub(x, key, idKind)];
    if (v is num && key == 'foreign_id') return int.parse(_map('foreign', '$v', (n) => '$n'));
    if (v is String) {
      switch (key) {
        case 'id' when idKind == 'transfer':
          return _map('transfer', v, (n) => 'TR$n');
        case 'account_id' || 'id' when RegExp(r'^\d{6,}$').hasMatch(v):
          return _map('account', v, (n) => '${1000 + n}');
        case 'base_account_id' || 'counter_account_id':
          return _map('account', v, (n) => '${1000 + n}');
        case 'order_id':
          return _map('order', v, (n) => 'BXORDER${n.toString().padLeft(7, '0')}');
        case 'trade_id':
          return _map('trade', v, (n) => 'T$n');
        case 'client_order_id':
          return '';
        case 'reference':
          return _map('ref', v, (n) => 'REF-$n');
        case 'txid' || 'transaction_id':
          return v.isEmpty ? v : _map('tx', v, (n) => 'txid-$n-scrubbed');
        case 'address':
          return v.isEmpty ? v : _map('addr', v, (n) => 'scrubbed-address-$n');
        case 'description':
          return _description(v);
        case 'name':
          return _freeText(v);
      }
      if (_amountKeys.contains(key)) {
        final d = Decimal.tryParse(v);
        if (d != null) return (d * factor).toString();
      }
      return v;
    }
    return v;
  }

  /// Digits carry amounts, prices and ids, so none survive in prose.
  static String _mask(String v) => v.replaceAll(RegExp(r'\d'), '#');

  /// Only generic ledger wording is kept (digits masked); the name of a wallet or person, or anything unfamiliar, is dropped.
  String _description(String v) {
    final masked = _mask(v);
    final moved = RegExp(r'^(Received|Sent) ([A-Za-z]+) (into|from|to) .*$').firstMatch(masked);
    if (moved != null) return '${moved[1]} ${moved[2]} ${moved[3]} wallet';
    const generic = [
      'Bought',
      'Sold',
      'Trading fee',
      'Deposit',
      'Withdrawal',
      'Reserved funds',
      'Released funds',
      'Interest',
      'Fee',
      'Received',
      'Sent',
    ];
    return generic.any(masked.startsWith) ? masked : '[scrubbed]';
  }

  /// Values of the human-readable `details` block: addresses and hashes are removed, everything else is digit-masked.
  Object? _detail(Object? v) {
    if (v is! String) return v;
    return RegExp(r'[A-Za-z0-9]{20,}').hasMatch(v) ? '[scrubbed]' : _mask(v);
  }

  /// Keeps short generic phrases ("Bought 0.01 XBT", "Trading fee"); blanks anything that could identify a person or place.
  String _freeText(String v) {
    final cleaned = v.replaceAll(RegExp(r'[A-Za-z0-9]{12,}'), '[id]').replaceAll(RegExp(r'\S+@\S+'), '[email]');
    return cleaned.length > 60 ? '[scrubbed]' : cleaned;
  }
}

String _encode(Object? json, {required bool ledger}) {
  var text = const JsonEncoder.withIndent('  ').convert(json);
  if (ledger) {
    final keys = _ledgerNumberKeys.join('|');
    text = text.replaceAllMapped(RegExp('("(?:$keys)": )"(-?[0-9.eE+-]+)"'), (m) => '${m[1]}${m[2]}');
  }
  return '$text\n';
}

/// Applies the scrubbing rules again to recorded files, without scaling amounts a second time.
void _rescrubDirectory(String path) {
  final scrubber = Scrubber(Decimal.one);
  final files = Directory(path).listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final json = decodeLunoJson(f.readAsStringSync());
    final ledger = name.startsWith('ledger_') || name.startsWith('pending');
    f.writeAsStringSync(_encode(scrubber.scrub(json, null, name.startsWith('transfers_') ? 'transfer' : 'account'), ledger: ledger));
    stdout.writeln('re-scrubbed $name');
  }
}

Future<void> main(List<String> args) async {
  final rescrub = args.indexOf('--rescrub');
  if (rescrub >= 0) {
    _rescrubDirectory(args.length > rescrub + 1 ? args[rescrub + 1] : 'test/fixtures/luno/live');
    return;
  }
  final id = Platform.environment['LUNO_KEY_ID'];
  final secret = Platform.environment['LUNO_KEY_SECRET'];
  if (id == null || secret == null || id.isEmpty || secret.isEmpty) {
    stderr.writeln('Set LUNO_KEY_ID and LUNO_KEY_SECRET in the environment (use a read-only key).');
    exit(64);
  }
  final outIndex = args.indexOf('--out');
  final out = Directory(outIndex >= 0 && outIndex + 1 < args.length ? args[outIndex + 1] : 'test/fixtures/luno/live')
    ..createSync(recursive: true);
  final factor = Decimal.parse(Platform.environment['LUNO_SCRUB_FACTOR'] ?? '0.37');
  final scrubber = Scrubber(factor);

  final dio = Dio(
    BaseOptions(baseUrl: 'https://api.luno.com', responseType: ResponseType.plain, followRedirects: false, validateStatus: (_) => true),
  );
  final auth = 'Basic ${base64.encode(utf8.encode('$id:$secret'))}';
  var calls = 0;

  Future<Json> get(String path, {Map<String, Object> query = const {}, bool authed = true}) async {
    if (calls++ > 0) await Future<void>.delayed(const Duration(milliseconds: 400)); // stay far below 300 calls/minute
    final r = await dio.get<String>(
      path,
      queryParameters: query,
      options: Options(headers: {if (authed) 'Authorization': auth, 'Accept': 'application/json'}),
    );
    if (r.statusCode != 200) {
      stderr.writeln('GET $path -> ${r.statusCode} ${'${r.data}'.length > 200 ? '' : r.data}');
      return const {};
    }
    return decodeLunoJson(r.data ?? '');
  }

  void save(String name, Object? json, {bool ledger = false, String idKind = 'account'}) {
    File('${out.path}/$name').writeAsStringSync(_encode(scrubber.scrub(json, null, idKind), ledger: ledger));
    stdout.writeln('wrote $name');
  }

  final balance = await get('/api/1/balance');
  save('balance.json', balance);
  final accounts = LunoMappers.balances(balance);
  final fiat = accounts
      .where((a) => a.asset.length == 3 && const {'MYR', 'ZAR', 'NGN', 'IDR', 'EUR', 'GBP', 'UGX', 'AUD'}.contains(a.asset))
      .map((a) => a.asset)
      .toSet();

  for (final a in accounts) {
    final name = a.asset.toLowerCase();
    save(
      'ledger_$name.json',
      await get('/api/1/accounts/${a.accountId}/transactions', query: {'min_row': 1, 'max_row': 1001}),
      ledger: true,
    );
    final pending = await get('/api/1/accounts/${a.accountId}/pending');
    if ((pending['pending'] as List?)?.isNotEmpty ?? false) save('pending_$name.json', pending, ledger: true);
    final transfers = await get('/api/exchange/1/transfers', query: {'account_id': a.accountId, 'limit': 100});
    if ((transfers['transfers'] as List?)?.isNotEmpty ?? false) save('transfers_$name.json', transfers, idKind: 'transfer');
  }

  final markets = await get('/api/exchange/1/markets', authed: false);
  final pairs = <String>[
    for (final m in LunoMappers.markets(markets))
      if (accounts.any((a) => a.asset == m.base) && (fiat.contains(m.counter) || accounts.any((a) => a.asset == m.counter))) m.pair,
  ];
  save('markets.json', {
    'markets': [
      for (final m in (markets['markets'] as List? ?? const []).whereType<Map<String, Object?>>())
        if (pairs.contains(m['market_id'])) m,
    ],
  });
  for (final p in pairs) {
    save('listtrades_${p.toLowerCase()}.json', await get('/api/1/listtrades', query: {'pair': p, 'limit': 1000}));
  }
  if (pairs.isNotEmpty) {
    save('tickers.json', await get('/api/1/tickers', query: {'pair': pairs}, authed: false));
    final first = pairs.first;
    save(
      'candles_1d.json',
      await get(
        '/api/exchange/1/candles',
        query: {'pair': first, 'since': DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch, 'duration': 86400},
      ),
    );
    save('fee_info.json', await get('/api/1/fee_info', query: {'pair': first}));
  }
  stdout.writeln('Done ($calls requests). Amounts were multiplied by $factor. Review test/fixtures/luno before committing.');
  exit(0);
}
