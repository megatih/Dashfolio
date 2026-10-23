import 'dart:io';

import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/luno/luno_client.dart';
import 'package:dashfolio/data/luno/luno_connect_service.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:dashfolio/data/luno/luno_mappers.dart';
import 'package:dashfolio/data/luno/luno_sync_service.dart';
import 'package:dashfolio/data/net/request_scheduler.dart';
import 'package:dashfolio/data/repositories/luno_repository_impl.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:dashfolio/domain/services/holdings_engine.dart';
import 'package:dashfolio/domain/services/luno_ledger_mapper.dart';
import 'package:dashfolio/domain/services/luno_reconciliation.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_luno_credentials.dart';
import '../../support/fake_luno_server.dart';
import '../../support/fake_market_data.dart';
import '../../support/luno_fixtures.dart';

/// Recorded from a real Luno account (MYR, eight wallets, 136 ledger rows, trades in seven coins) by
/// `tool/record_luno_fixtures.dart`, then scrubbed and scaled. These tests pin down what Luno's ledger really looks like.
const _live = 'test/fixtures/luno/live';

/// The recording of a real account is git-ignored (see test/fixtures/luno/README.md), so these tests only run where it was recorded.
final String? _skipLive = Directory(_live).existsSync() ? null : 'live Luno recordings are not committed';

String _read(String name) => File('$_live/$name').readAsStringSync();

List<LunoLedgerEntry> _ledger() => [
  // Groups build their fixtures while declaring, i.e. also when skipped.
  if (_skipLive == null)
    for (final f in Directory(_live).listSync().whereType<File>().where((f) => f.uri.pathSegments.last.startsWith('ledger_')))
      ...LunoMappers.ledger(decodeLunoJson(f.readAsStringSync())),
];

List<LunoAccount> _accounts() => LunoMappers.balances(decodeLunoJson(_read('balance.json')));

LunoMapContext _ctx() => LunoMapContext(
  portfolioId: 1,
  connectionId: 1,
  homeFiat: 'MYR',
  now: DateTime.utc(2026, 10, 22),
  priceOf: (asset, at) => Decimal.fromInt(100),
  fxToBase: (c, at) => Decimal.one,
);

void main() {
  group('every recorded endpoint parses', () {
    test('balances: eight wallets, nothing reserved or unconfirmed', () {
      final a = _accounts();
      expect(a.map((x) => x.asset).toSet(), {'XBT', 'CRV', 'ETH', 'LINK', 'LTC', 'MYR', 'SOL', 'XRP'});
      expect(a.every((x) => x.reserved == Decimal.zero && x.unconfirmed == Decimal.zero), isTrue);
      expect(a.every((x) => x.accountType == 'TRANSACTIONAL'), isTrue);
    });

    test('markets, tickers, candles and fee info', () {
      final markets = LunoMappers.markets(decodeLunoJson(_read('markets.json')));
      expect(markets.length, 13);
      expect(markets.every((m) => m.status == LunoMarketStatus.active && m.pair == '${m.base}${m.counter}'), isTrue);
      final tickers = LunoMappers.tickers(decodeLunoJson(_read('tickers.json')));
      expect(tickers.length, 13);
      expect(tickers.every((t) => t.lastTrade != null && t.bid != null && t.ask != null && t.volume24h != null), isTrue);
      final candles = LunoMappers.candles(decodeLunoJson(_read('candles_1d.json')));
      expect(candles.length, 29);
      expect(candles.first.timestamp.isBefore(candles.last.timestamp) || candles.first.timestamp == candles.last.timestamp, isTrue);
      expect(candles.every((c) => c.high >= c.low), isTrue);
      expect(lunoFeeInfo(decodeLunoJson(_read('fee_info.json'))).takerFeeBuy, Decimal.parse('0.001'));
    });

    test('transfers and the user\'s trades', () {
      final deposits = LunoMappers.transfers(decodeLunoJson(_read('transfers_myr.json')));
      expect(deposits.map((t) => t.inbound), [true, true]);
      expect(deposits.every((t) => t.amount > Decimal.zero), isTrue);
      final btc = LunoMappers.transfers(decodeLunoJson(_read('transfers_xbt.json')));
      expect(btc.every((t) => t.transactionId != null), isTrue);
      final trades = LunoMappers.trades(decodeLunoJson(_read('listtrades_xbtmyr.json')));
      expect(trades.length, 8);
      expect(trades.every((t) => t.pair == 'XBTMYR' && t.price > Decimal.zero), isTrue);
      expect(trades.map((t) => t.isBuy).toSet(), {true, false}, reason: 'both sides of the market were traded');
    });

    test('ledger pages come newest first; limit-order fills carry trade_details, instant buys do not', () {
      final xbt = LunoMappers.ledger(decodeLunoJson(_read('ledger_xbt.json')));
      expect(xbt.first.rowIndex, greaterThan(xbt.last.rowIndex));
      final exchange = xbt.where((e) => e.kind == LunoLedgerKind.exchange).toList();
      expect(exchange.where((e) => e.tradePair != null), isNotEmpty, reason: 'limit-order fills describe their pair, price and sequence');
      expect(exchange.where((e) => e.tradePair == null), isNotEmpty, reason: 'instant buys do not, so pairing cannot depend on it');
      expect(xbt.where((e) => e.kind == LunoLedgerKind.transfer).every((e) => e.txId != null), isTrue);
    });
  }, skip: _skipLive);

  group('the real ledger', () {
    final entries = _ledger();
    final result = const LunoLedgerMapper().map(entries, _ctx());

    test('contains the shapes the mapper was built for, plus order bookkeeping', () {
      final kinds = <LunoLedgerKind, int>{};
      for (final e in entries) {
        kinds[e.kind] = (kinds[e.kind] ?? 0) + 1;
      }
      expect(entries.length, 136);
      expect(kinds, {LunoLedgerKind.exchange: 54, LunoLedgerKind.fee: 24, LunoLedgerKind.transfer: 4, LunoLedgerKind.unknown: 54});
      expect(entries.where((e) => e.kind == LunoLedgerKind.unknown).every((e) => e.balanceDelta == Decimal.zero), isTrue);
    });

    test('every row is understood: nothing unrecognised, nothing held back, no warnings', () {
      expect(result.mapped.length, 136);
      expect(result.unrecognised, isEmpty);
      expect(result.deferred, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('27 trades (each leg pairs with its counterpart), 2 bank deposits and 2 receives, with fees folded into the trades', () {
      final byType = <TxType, int>{};
      for (final t in result.transactions) {
        byType[t.type] = (byType[t.type] ?? 0) + 1;
      }
      expect(byType, {TxType.buy: 20, TxType.sell: 7, TxType.deposit: 2, TxType.transferIn: 2});
      expect(result.transactions.where((t) => t.type == TxType.fee), isEmpty);
      expect(result.transactions.map((t) => t.externalId).toSet().length, 31);
      expect(result.transactions.every((t) => t.symbol == null || t.symbol!.endsWith('MYR')), isTrue, reason: 'one position per coin');
      final trades = result.transactions.where((t) => t.type == TxType.buy || t.type == TxType.sell);
      expect(trades.every((t) => t.quantity > Decimal.zero && t.price > Decimal.zero), isTrue);
      expect(trades.where((t) => t.notes?.startsWith('Includes fee of') ?? false).length, 24);
    });

    test('replayed, every coin equals the balance Luno reports, with FIFO and average cost alike', () {
      for (final method in CostMethod.values) {
        final pos = const HoldingsEngine().replay(result.transactions, method);
        expect(pos.warnings, isEmpty, reason: '$method');
        final held = {for (final p in pos.positions.values) p.symbol: p.quantity};
        expect(
          reconcileLuno(accounts: _accounts(), heldBySymbol: held),
          isEmpty,
          reason: '$method: $held',
        );
        expect(pos.positions.values.every((p) => p.quantity >= Decimal.zero), isTrue);
      }
    });

    test('derived cash equals the sum of the MYR wallet\'s balance changes', () {
      final pos = const HoldingsEngine().replay(result.transactions, CostMethod.average);
      final myr = entries.where((e) => e.asset == 'MYR').fold(Decimal.zero, (s, e) => s + e.balanceDelta);
      expect((pos.cashBase - myr).abs() < Decimal.parse('0.000001'), isTrue, reason: '${pos.cashBase} vs $myr');
    });

    test('the result does not depend on the order rows arrive in', () {
      final reversed = const LunoLedgerMapper().map(entries.reversed, _ctx());
      expect(
        reversed.transactions.map((t) => '${t.externalId}|${t.quantity}|${t.price}').toList(),
        result.transactions.map((t) => '${t.externalId}|${t.quantity}|${t.price}').toList(),
      );
    });
  }, skip: _skipLive);

  group('syncing the real account end to end', () {
    late AppDatabase db;
    late FakeLunoServer server;
    late LunoRepositoryImpl luno;
    late PortfolioRepositoryImpl portfolios;
    late LunoSyncService sync;
    late int connectionId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      server = FakeLunoServer(dir: 'live');
      luno = LunoRepositoryImpl(db);
      final clock = FixedClock(DateTime.utc(2026, 10, 22, 12));
      portfolios = PortfolioRepositoryImpl(db, clock);
      final dio = Dio()..httpClientAdapter = server.adapter;
      const creds = LunoCredentials(keyId: 'abcd1234keyid', keySecret: 'SUPERSECRET-0123456789');
      final connect = LunoConnectService(store: FakeLunoCredentialStore(), luno: luno, portfolios: portfolios, dio: dio);
      final check = await connect.verify(creds);
      expect(check.acceptable, isTrue);
      connectionId = await connect.connect(
        credentials: creds,
        check: check,
        label: 'Real',
        homeFiat: LunoConnectService.suggestHomeFiat(check.accounts),
        costMethod: CostMethod.fifo,
      );
      final market = FakeMarketData()..daily['LUNO:XBTMYR'] = fakeCandles('2022-06-01', List.filled(1600, 150000.0));
      sync = LunoSyncService(
        luno: luno,
        portfolios: portfolios,
        market: market,
        clock: clock,
        clientFor: (_) => LunoClient(dio: dio, credentials: () async => creds, scheduler: RequestScheduler(), backoff: (_) async {}),
      );
      server.requests.clear();
    });
    tearDown(() => db.close());

    test('the home currency is detected, a first sync reconciles every coin, and an idle sync costs one request', () async {
      expect((await luno.getConnection(connectionId))!.homeFiat, 'MYR');
      final r = await sync.sync(connectionId, baseCurrency: 'MYR');
      expect(r.ok, isTrue, reason: '${r.failure}');
      expect((r.rowsFetched, r.transactions, r.unrecognised, r.deferred), (136, 31, 0, 0));
      expect(r.mismatches, isEmpty);
      expect(server.requests.length, 1 + 8, reason: 'one balance call and one ledger page per wallet');

      final c = (await luno.getConnection(connectionId))!;
      expect((c.status, c.lastError, c.unrecognisedRows), (LunoConnectionStatus.ok, null, 0));
      expect((await luno.syncedTransactions(connectionId)).length, 31);

      server.requests.clear();
      final idle = await sync.sync(connectionId, baseCurrency: 'MYR');
      expect(idle.ok, isTrue);
      expect(server.requests.length, 1);
    });

    test('a new trade appearing later is picked up from the cursor, and only for the wallets that changed', () async {
      await sync.sync(connectionId, baseCurrency: 'MYR');
      final xbt = server.ledgers.values.firstWhere((l) => l.first['currency'] == 'XBT');
      final myr = server.ledgers.values.firstWhere((l) => l.first['currency'] == 'MYR');
      final xbtNext = (xbt.map((r) => r['row_index']! as int).reduce((a, b) => a > b ? a : b)) + 1;
      final myrNext = (myr.map((r) => r['row_index']! as int).reduce((a, b) => a > b ? a : b)) + 1;
      final at = DateTime.utc(2026, 10, 22, 10).millisecondsSinceEpoch;
      Map<String, Object?> leg(Map<String, Object?> base, int index, String currency, num delta, String? kind) => {
        'row_index': index,
        'timestamp': at,
        'balance': 1,
        'available': 1,
        'account_id': base['account_id'],
        'balance_delta': delta,
        'available_delta': delta,
        'currency': currency,
        'description': 'Bought BTC',
        'details': <String, Object?>{},
        'detail_fields': <String, Object?>{},
        'kind': ?kind,
        'type': 14,
        'foreign_id': 1,
        'reference': 'REF-NEW',
      };
      xbt.insert(0, leg(xbt.first, xbtNext, 'XBT', 0.001, 'EXCHANGE'));
      myr.insert(0, leg(myr.first, myrNext, 'MYR', -300, 'EXCHANGE'));
      server.setBalance('XBT', balance: (Decimal.parse('${server.balanceOf('XBT')['balance']}') + Decimal.parse('0.001')).toString());
      server.setBalance('MYR', balance: (Decimal.parse('${server.balanceOf('MYR')['balance']}') - Decimal.parse('300')).toString());

      server.requests.clear();
      final r = await sync.sync(connectionId, baseCurrency: 'MYR');
      expect(r.ok, isTrue, reason: '${r.failure}');
      expect((r.rowsFetched, r.transactions), (2, 1));
      expect(r.mismatches, isEmpty);
      expect(server.ledgerRequests.length, 2, reason: 'only the two wallets whose balance changed');
      expect((await luno.syncedTransactions(connectionId)).length, 32);
    });
  }, skip: _skipLive);

  group('committed fixtures contain nothing identifying', () {
    final files = Directory('test/fixtures/luno')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    test('there are fixtures to check', () => expect(files.length, greaterThan(15)));

    test('no wallet addresses, transaction hashes, e-mails or names in free text', () {
      final address = RegExp(r'\b(bc1[a-z0-9]{20,}|[13][a-km-zA-HJ-NP-Z1-9]{25,34}|0x[0-9a-fA-F]{30,})\b');
      final hash = RegExp(r'\b[0-9a-fA-F]{40,}\b');
      final email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
      for (final f in files) {
        final text = f.readAsStringSync();
        expect(address.hasMatch(text), isFalse, reason: '${f.path} has an address');
        expect(hash.hasMatch(text), isFalse, reason: '${f.path} has a hash');
        expect(email.hasMatch(text), isFalse, reason: '${f.path} has an e-mail');
      }
    });

    test('the human-readable details and descriptions of recorded ledgers carry no digits or long tokens', () {
      for (final f in files.where((f) => f.path.contains('/live/') && f.uri.pathSegments.last.startsWith('ledger_'))) {
        final rows = (rawJson('live/${f.uri.pathSegments.last}')! as Map<String, Object?>)['transactions']! as List;
        for (final r in rows.cast<Map<String, Object?>>()) {
          final description = '${r['description']}';
          expect(
            description,
            anyOf(matches(RegExp(r'^[^0-9]*$')), matches(RegExp(r'^(Bought|Sold) [^0-9]*$'))),
            reason: '${f.path}: $description',
          );
          for (final v in (r['details']! as Map<String, Object?>).values) {
            expect(RegExp(r'[0-9]').hasMatch('$v'), isFalse, reason: '${f.path}: $v');
            expect(RegExp(r'[A-Za-z0-9]{20,}').hasMatch('$v'), isFalse, reason: '${f.path}: $v');
          }
        }
      }
    });
  });
}
