import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/data/luno/luno_client.dart';
import 'package:dashfolio/data/luno/luno_connect_service.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:dashfolio/data/luno/luno_sync_service.dart';
import 'package:dashfolio/data/net/request_scheduler.dart';
import 'package:dashfolio/data/repositories/luno_repository_impl.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/design_system/app/app_ui.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:dashfolio/features/lock/lock_controller.dart';
import 'package:dashfolio/features/lock/lock_service.dart';
import 'package:dashfolio/features/transactions/transactions_list.dart';
import 'package:dashfolio/app/refresh_controller.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/routing/router.dart';
import 'package:dashfolio/routing/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/finders.dart';
import '../support/fake_luno_server.dart';
import '../support/fake_market_data.dart';
import '../support/fonts.dart';

const _creds = LunoCredentials(keyId: 'abcd1234keyid', keySecret: 'SUPERSECRET-0123456789');

Finder field(String label) =>
    find.descendant(of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label), matching: find.byType(EditableText));

void main() {
  setUpAll(loadAppFonts);
  for (final skin in AppSkin.values) {
    group(skin.name, () {
      late FakeLunoServer server;
      late LunoConnection connection;

      /// A connected, synced account, written before the app starts (writes made after it has live drift streams, from
      /// `runAsync`, would deadlock across zones).
      Future<LunoConnection> seedConnection(WidgetTester tester, AppHarness h) async {
        return (await tester.runAsync(() async {
          final dio = Dio()..httpClientAdapter = server.adapter;
          final luno = LunoRepositoryImpl(h.db);
          final portfolios = PortfolioRepositoryImpl(h.db, h.clock);
          final connect = LunoConnectService(store: h.lunoCredentials, luno: luno, portfolios: portfolios, dio: dio);
          final id = await connect.connect(
            credentials: _creds,
            check: await connect.verify(_creds),
            label: 'Main',
            homeFiat: 'MYR',
            costMethod: CostMethod.average,
            sendPermissionConfirmedAbsent: true,
          );
          final sync = LunoSyncService(
            luno: luno,
            portfolios: portfolios,
            market: h.market,
            clock: h.clock,
            clientFor: (_) => LunoClient(dio: dio, credentials: () async => _creds, scheduler: RequestScheduler()),
          );
          final r = await sync.sync(id, baseCurrency: 'MYR');
          expect(r.ok, isTrue, reason: '${r.failure}');
          return (await luno.getConnection(id))!;
        }))!;
      }

      /// Starts the app against an in-memory Luno. With [lock] the app lock is on (PIN 2468) and already unlocked.
      Future<AppHarness> start(
        WidgetTester tester, {
        bool lock = true,
        bool connected = false,
        bool warn = false,
        void Function(FakeLunoServer server)? prepare,
        Size size = const Size(1200, 1600),
      }) async {
        server = FakeLunoServer();
        prepare?.call(server);
        final h = AppHarness.create(skin: skin, now: DateTime.utc(2024, 6, 1, 12));
        await h.completeOnboarding(baseCurrency: 'MYR');
        h.market.daily['LUNO:XBTEUR'] = fakeCandles('2023-12-01', List.filled(250, 55000.0));
        h.market.daily['LUNO:XBTMYR'] = fakeCandles('2023-12-01', List.filled(250, 260000.0));
        h.market.daily['LUNO:ETHMYR'] = fakeCandles('2023-12-01', List.filled(250, 8000.0));
        h.extraOverrides.addAll([
          lunoDioProvider.overrideWithValue(Dio()..httpClientAdapter = server.adapter),
          lunoSchedulerProvider.overrideWithValue(RequestScheduler()),
        ]);
        if (lock) {
          await tester.runAsync(() async {
            await h.pins.write('s', const PinHasher(iterations: 10).hash('2468', 's'));
            await SettingsRepositoryLike(h.db).set('lock_enabled', 'true');
          });
        }
        if (connected) {
          connection = await seedConnection(tester, h);
          if (warn) await tester.runAsync(() => LunoRepositoryImpl(h.db).updateConnection(connection.copyWith(writePermWarning: true)));
        }
        await h.pump(tester, size: size);
        if (lock) {
          await tester.runAsync(() => h.container.read(lockControllerProvider.notifier).unlockWithPin('2468'));
          await h.settle(tester);
        }
        return h;
      }

      void go(AppHarness h, String location) => h.container.read(routerProvider).go(location);

      Future<void> enterPin(WidgetTester tester, AppHarness h) async {
        await tester.enterText(field('Current PIN'), '2468');
        await tester.tap(find.text('Continue'));
        await h.settle(tester, frames: 20);
      }

      group('connect wizard', () {
        testWidgets('asks to turn on the app lock first, and offers no key form', (tester) async {
          final h = await start(tester, lock: false);
          go(h, Routes.lunoConnect);
          await h.settle(tester, frames: 20);
          expect(find.text('Turn on the app lock first'), findsOneWidget);
          expect(find.text('I have my key'), findsNothing);
          expect(field('API key secret'), findsNothing);
          await h.dispose(tester);
        });

        testWidgets('checks the key, connects, syncs, and leaves no secret in the form', (tester) async {
          final h = await start(tester);
          go(h, Routes.lunoConnect);
          await h.settle(tester, frames: 20);

          // The key form is behind step-up authentication.
          expect(field('API key ID'), findsNothing);
          await tester.tap(find.text('I have my key'));
          await h.settle(tester, frames: 15);
          await enterPin(tester, h);
          expect(field('API key ID'), findsOneWidget);

          // Credential fields are sensitive: obscured, no suggestions or autocorrect.
          final secret = tester.widget<EditableText>(field('API key secret'));
          expect(
            (secret.obscureText, secret.autocorrect, secret.enableSuggestions, secret.enableIMEPersonalizedLearning),
            (true, false, false, false),
          );

          await tester.enterText(field('API key ID'), _creds.keyId);
          await tester.enterText(field('API key secret'), _creds.keySecret);
          await tester.pump();
          await tester.tap(find.text('Check key'));
          await h.settle(tester, frames: 40);

          expect(find.textContaining('can read your account and cannot place orders'), findsOneWidget);
          expect(find.textContaining('…eyid'), findsOneWidget);
          expect(find.text('Create or stop orders: not allowed'), findsOneWidget);
          // Once checked, the form no longer holds the secret.
          expect(tester.widget<EditableText>(field('API key secret')).controller.text, isEmpty);
          expect(tester.widget<EditableText>(field('API key ID')).controller.text, isEmpty);

          await tester.ensureVisible(find.text('Connect and sync'));
          await tester.tap(find.text('Connect and sync'));
          await h.settle(tester, frames: 60);

          expect(find.textContaining('Synced 9 transactions from 15 ledger entries'), findsOneWidget);
          final conn = (await tester.runAsync(() => LunoRepositoryImpl(h.db).getConnections()))!.single;
          expect((conn.label, conn.homeFiat, conn.status, conn.keyIdHint), ('Luno', 'MYR', LunoConnectionStatus.ok, 'eyid'));
          expect(conn.writePermWarning, isTrue, reason: 'the user did not attest that the send permission is absent');
          expect((await h.lunoCredentials.read(conn.id))!.keySecret, _creds.keySecret);
          final portfolios = (await tester.runAsync(() => PortfolioRepositoryImpl(h.db, h.clock).getPortfolios()))!;
          expect(portfolios.single.name, 'Luno – Luno');
          await h.dispose(tester);
        });

        testWidgets('a key that can place orders is refused: the problem is explained and nothing is created', (tester) async {
          final h = await start(tester);
          server.canStopOrders = true;
          go(h, Routes.lunoConnect);
          await h.settle(tester, frames: 20);
          await tester.tap(find.text('I have my key'));
          await h.settle(tester, frames: 15);
          await enterPin(tester, h);
          await tester.enterText(field('API key ID'), _creds.keyId);
          await tester.enterText(field('API key secret'), _creds.keySecret);
          await tester.pump();
          await tester.tap(find.text('Check key'));
          await h.settle(tester, frames: 40);

          expect(find.textContaining('Create or stop orders: ALLOWED'), findsOneWidget);
          expect(find.textContaining('can place orders or withdraw funds'), findsWidgets);
          expect(find.text('Connect and sync'), findsNothing);
          expect(tester.widget<EditableText>(field('API key secret')).controller.text, isEmpty, reason: 'a refused secret is erased too');
          expect((await tester.runAsync(() => LunoRepositoryImpl(h.db).getConnections()))!, isEmpty);
          expect(h.lunoCredentials.connectionIds, isEmpty);
          await h.dispose(tester);
        });

        testWidgets('a revoked or invalid key shows a friendly error', (tester) async {
          final h = await start(tester);
          server.revoked = true;
          go(h, Routes.lunoConnect);
          await h.settle(tester, frames: 20);
          await tester.tap(find.text('I have my key'));
          await h.settle(tester, frames: 15);
          await enterPin(tester, h);
          await tester.enterText(field('API key ID'), 'bad');
          await tester.enterText(field('API key secret'), 'bad');
          await tester.pump();
          await tester.tap(find.text('Check key'));
          await h.settle(tester, frames: 40);
          expect(find.textContaining('Luno rejected the API key'), findsOneWidget);
          await h.dispose(tester);
        });

        testWidgets('a wrong PIN keeps the key form closed', (tester) async {
          final h = await start(tester);
          go(h, Routes.lunoConnect);
          await h.settle(tester, frames: 20);
          await tester.tap(find.text('I have my key'));
          await h.settle(tester, frames: 15);
          await tester.enterText(field('Current PIN'), '0000');
          await tester.tap(find.text('Continue'));
          await h.settle(tester, frames: 20);
          expect(find.text('Incorrect PIN'), findsOneWidget);
          expect(field('API key ID'), findsNothing);
          await h.dispose(tester);
        });
      });

      group('connections', () {
        testWidgets('settings lists the connection, and the connections page shows its status and key hint', (tester) async {
          final h = await start(tester, connected: true);
          go(h, Routes.settings);
          await h.settle(tester, frames: 20);
          expect(find.text('Luno'), findsWidgets);
          expect(find.text('Manage connections'), findsOneWidget);

          go(h, Routes.luno);
          await h.settle(tester, frames: 20);
          expect(find.text('Main'), findsOneWidget);
          expect(find.text('Synced'), findsWidgets);
          expect(find.text('Key …eyid'), findsOneWidget);
          await h.dispose(tester);
        });

        testWidgets('the detail page offers sync, replace key and disconnect, and shows the send-permission warning', (tester) async {
          final h = await start(tester, connected: true, warn: true);
          final c = connection;
          go(h, Routes.lunoConnection(c.id));
          await h.settle(tester, frames: 20);
          expect(find.text('This key might be able to send funds'), findsOneWidget);
          for (final label in ['Sync now', 'Replace key', 'Disconnect', 'Rename', 'Open portfolio']) {
            expect(find.text(label), findsWidgets, reason: label);
          }

          await tester.ensureVisible(find.text('I checked: it has no send permission'));
          await tester.tap(find.text('I checked: it has no send permission'));
          await h.settle(tester, frames: 20);
          expect(find.text('This key might be able to send funds'), findsNothing);
          await h.dispose(tester);
        });

        testWidgets('disconnecting needs the PIN, deletes the key at once, and can keep the portfolio', (tester) async {
          final h = await start(tester, connected: true);
          final c = connection;
          go(h, Routes.lunoConnection(c.id));
          await h.settle(tester, frames: 20);

          await tester.ensureVisible(find.text('Disconnect').last);
          await tester.tap(find.text('Disconnect').last);
          await h.settle(tester, frames: 15);
          await enterPin(tester, h);
          expect(find.text('Disconnect "Main"?'), findsOneWidget);
          await tester.tap(find.text('Keep portfolio'));
          await h.settle(tester, frames: 30);

          expect(await h.lunoCredentials.read(c.id), isNull);
          expect((await tester.runAsync(() => LunoRepositoryImpl(h.db).getConnections()))!, isEmpty);
          final txs = (await tester.runAsync(() => PortfolioRepositoryImpl(h.db, h.clock).getTransactions()))!;
          expect(txs.length, 9);
          expect(txs.every((t) => !t.isSynced), isTrue, reason: 'kept as an ordinary, editable portfolio');
          await h.dispose(tester);
        });

        testWidgets('replacing the key needs the PIN, verifies the new key, and stores it in place of the old one', (tester) async {
          final h = await start(tester, connected: true);
          final c = connection;
          go(h, Routes.lunoConnection(c.id));
          await h.settle(tester, frames: 20);
          await tester.tap(find.text('Replace key').last);
          await h.settle(tester, frames: 15);
          await enterPin(tester, h);

          await tester.enterText(field('API key ID'), 'newkeyid5678');
          await tester.enterText(field('API key secret'), 'OTHERSECRET-9876543210');
          await tester.pump();
          await tester.tap(find.text('Verify and replace'));
          await h.settle(tester, frames: 60);

          final stored = (await h.lunoCredentials.read(c.id))!;
          expect((stored.keyId, stored.keySecret), ('newkeyid5678', 'OTHERSECRET-9876543210'));
          expect((await tester.runAsync(() => LunoRepositoryImpl(h.db).getConnection(c.id)))!.keyIdHint, '5678');
          await h.dispose(tester);
        });

        testWidgets('a replacement key that can place orders is refused and the old key stays', (tester) async {
          final h = await start(tester, connected: true);
          final c = connection;
          server.canStopOrders = true;
          go(h, Routes.lunoConnection(c.id));
          await h.settle(tester, frames: 20);
          await tester.tap(find.text('Replace key').last);
          await h.settle(tester, frames: 15);
          await enterPin(tester, h);
          await tester.enterText(field('API key ID'), 'newkeyid5678');
          await tester.enterText(field('API key secret'), 'OTHERSECRET-9876543210');
          await tester.pump();
          await tester.tap(find.text('Verify and replace'));
          await h.settle(tester, frames: 60);

          expect(find.textContaining('can place orders or withdraw funds'), findsOneWidget);
          expect((await h.lunoCredentials.read(c.id))!.keyId, _creds.keyId);
          expect(tester.widget<EditableText>(field('API key secret')).controller.text, isEmpty, reason: 'the refused secret is erased');
          await h.dispose(tester);
        });

        testWidgets('rename, change currency (rebuilds the transactions), and Sync now', (tester) async {
          final h = await start(tester, connected: true);
          final c = connection;
          go(h, Routes.lunoConnection(c.id));
          await h.settle(tester, frames: 20);

          await tester.tap(find.text('Rename'));
          await h.settle(tester, frames: 15);
          await tester.enterText(field('Name'), 'Savings');
          await tester.tap(find.text('Save'));
          await h.settle(tester, frames: 20);
          expect(find.text('Savings'), findsWidgets);

          await tester.tap(find.text('Currency'));
          await h.settle(tester, frames: 15);
          await tester.tap(find.byType(AppSelect<String>).last);
          await h.settle(tester, frames: 10);
          if (skin == AppSkin.cupertino) {
            // A long list opens a wheel: scroll it from the current currency to EUR, then confirm.
            final sorted = lunoFiatCurrencies.toList()..sort();
            final steps = sorted.indexOf('EUR') - sorted.indexOf('MYR');
            // The drag gesture swallows the touch slop (18 px) before it starts moving the wheel.
            await tester.drag(find.byType(CupertinoPicker), Offset(0, -36.0 * steps + (steps < 0 ? kTouchSlop : -kTouchSlop)));
            await h.settle(tester, frames: 10);
            await tester.tap(find.text('Done'));
          } else {
            await tester.tap(find.text('EUR').last);
          }
          await h.settle(tester, frames: 10);
          await tester.tap(find.text('Change'));
          await h.settle(tester, frames: 60);
          final conn = (await tester.runAsync(() => LunoRepositoryImpl(h.db).getConnection(c.id)))!;
          expect((conn.label, conn.homeFiat), ('Savings', 'EUR'));
          final txs = (await tester.runAsync(() => LunoRepositoryImpl(h.db).syncedTransactions(c.id)))!;
          expect(txs.length, 9);
          expect(
            txs.where((t) => t.symbol != null).every((t) => t.symbol!.endsWith('EUR') && t.currency == 'EUR'),
            isTrue,
            reason: 'one position per asset, in the home currency',
          );
          expect(txs.any((t) => t.symbol == 'LUNO:XBTEUR' && t.type == TxType.buy && t.notes == 'Paid in MYR'), isTrue);
          expect(txs.any((t) => t.symbol == 'LUNO:XBTEUR' && t.type == TxType.transferIn), isTrue);
          server.requests.clear();
          await tester.tap(find.text('Sync now'));
          await h.settle(tester, frames: 40);
          expect(server.requests.where((r) => r.uri.path == '/api/1/balance').length, greaterThanOrEqualTo(1));
          expect(find.textContaining('up to date'), findsWidgets);
          await h.dispose(tester);
        });

        testWidgets('ledger entries that are not understood are listed for review and never imported', (tester) async {
          final h = await start(
            tester,
            connected: true,
            prepare: (s) {
              s.ledgers['1001']!.add({
                'row_index': 8,
                'timestamp': DateTime.utc(2024, 5, 21).millisecondsSinceEpoch,
                'balance': 1598,
                'available': 1598,
                'balance_delta': 5,
                'available_delta': 5,
                'currency': 'MYR',
                'kind': 'SOMETHING_NEW',
                'reference': 'Z',
                'description': 'A kind of entry from the future',
                'account_id': '1001',
              });
            },
          );
          final c = connection;
          go(h, Routes.lunoConnection(c.id));
          await h.settle(tester, frames: 20);
          expect(find.text('1 ledger entries were not recognised'), findsOneWidget);
          await tester.ensureVisible(find.text('Review'));
          await tester.tap(find.text('Review'));
          await h.settle(tester, frames: 20);
          expect(find.textContaining('A kind of entry from the future'), findsOneWidget);
          expect(find.text('Entries that were not imported'), findsOneWidget);
          await tester.tap(find.text('Close'));
          await h.settle(tester, frames: 10);

          await tester.tap(find.text('Rebuild from history'));
          await h.settle(tester, frames: 40);
          expect((await tester.runAsync(() => LunoRepositoryImpl(h.db).syncedTransactions(c.id)))!.length, 9);
          await h.dispose(tester);
        });

        testWidgets('deleting the portfolio of a synced account goes through the disconnect flow so the key is erased', (tester) async {
          final h = await start(tester, connected: true);
          final c = connection;
          go(h, Routes.portfolios);
          await h.settle(tester, frames: 25);
          expect(find.textContaining('Luno · synced'), findsOneWidget);

          await tester.tap(byAction('Portfolio actions'));
          await h.settle(tester);
          await tester.tap(find.text('Delete'));
          await h.settle(tester, frames: 15);
          await enterPin(tester, h);
          expect(find.text('Disconnect "Main"?'), findsOneWidget, reason: 'not a plain delete');
          await tester.tap(find.text('Delete portfolio'));
          await h.settle(tester, frames: 15);
          await tester.tap(find.text('Delete').last);
          await h.settle(tester, frames: 30);

          expect(await h.lunoCredentials.read(c.id), isNull);
          expect((await tester.runAsync(() => PortfolioRepositoryImpl(h.db, h.clock).getPortfolios()))!, isEmpty);
          await h.dispose(tester);
        });
      });

      group('synced portfolio is read-only', () {
        testWidgets('no add-transaction actions, a Luno badge, and the transactions show a lock', (tester) async {
          final h = await start(tester, connected: true);
          final c = connection;
          go(h, Routes.portfolio(c.portfolioId));
          await h.settle(tester, frames: 30);

          expect(find.textContaining('Luno · synced'), findsOneWidget);
          expect(byAction('Add transaction'), findsNothing);
          expect(byAction('Luno connection'), findsWidgets);

          await tester.tap(find.text('Transactions'));
          await h.settle(tester, frames: 20);
          expect(find.descendant(of: find.byType(TransactionsList), matching: byAppIcon(AppIcon.lock)), findsWidgets);
          await h.dispose(tester);
        });

        testWidgets('tapping a synced transaction opens a read-only sheet where only the note can be changed', (tester) async {
          final h = await start(tester, connected: true);
          final c = connection;
          go(h, Routes.portfolio(c.portfolioId));
          await h.settle(tester, frames: 30);
          await tester.tap(find.text('Transactions'));
          await h.settle(tester, frames: 20);

          await tester.tap(find.text('BUY').first);
          await h.settle(tester, frames: 20);
          expect(find.textContaining('Synced from Luno'), findsOneWidget);
          expect(find.text('Save note'), findsOneWidget);
          expect(find.text('Delete'), findsNothing);
          expect(field('Quantity'), findsNothing, reason: 'no editable amount fields');

          await tester.enterText(field('Note'), 'tax lot A');
          await tester.tap(find.text('Save note'));
          await h.settle(tester, frames: 20);
          final txs = (await tester.runAsync(() => LunoRepositoryImpl(h.db).syncedTransactions(c.id)))!;
          expect(txs.where((t) => t.notes == 'tax lot A'), hasLength(1));
          expect(txs.length, 9);
          await h.dispose(tester);
        });

        testWidgets('a new transaction can never be added to a synced portfolio', (tester) async {
          final h = await start(tester, connected: true);
          final c = connection;
          go(h, Routes.holding(c.portfolioId, 'LUNO:XBTMYR'));
          await h.settle(tester, frames: 30);
          expect(byAction('Add transaction'), findsNothing);
          await h.dispose(tester);
        });
      });

      group('where Luno is unsupported (web)', () {
        testWidgets('settings has no Luno section and the Luno routes bounce back to settings', (tester) async {
          server = FakeLunoServer();
          final h = AppHarness.create(skin: skin, now: DateTime.utc(2024, 6, 1, 12));
          await h.completeOnboarding(baseCurrency: 'MYR');
          h.extraOverrides.add(lunoSupportedProvider.overrideWithValue(false));
          await h.pump(tester, size: const Size(1200, 1600));

          go(h, Routes.settings);
          await h.settle(tester, frames: 20);
          expect(find.text('Appearance'), findsOneWidget);
          expect(find.text('Connect Luno'), findsNothing);
          expect(find.textContaining('Luno API key'), findsNothing);

          for (final path in [Routes.luno, Routes.lunoConnect, Routes.lunoConnection(1)]) {
            go(h, path);
            await h.settle(tester, frames: 20);
            expect(find.text('Appearance'), findsOneWidget, reason: '$path should fall back to settings');
            expect(find.text('Connect Luno'), findsNothing, reason: path);
          }
          await h.dispose(tester);
        });

        testWidgets('a refresh never contacts Luno, even if a connection came in with a restored backup', (tester) async {
          server = FakeLunoServer();
          final h = AppHarness.create(skin: skin, now: DateTime.utc(2024, 6, 1, 12));
          await h.completeOnboarding(baseCurrency: 'MYR');
          h.extraOverrides.addAll([
            lunoSupportedProvider.overrideWithValue(false),
            lunoDioProvider.overrideWithValue(Dio()..httpClientAdapter = server.adapter),
          ]);
          await tester.runAsync(() async {
            final portfolios = PortfolioRepositoryImpl(h.db, h.clock);
            final pid = await portfolios.createPortfolio(const NewPortfolio(name: 'Luno – Main'));
            await LunoRepositoryImpl(h.db)
                .createConnection(label: 'Main', portfolioId: pid, keyIdHint: 'abcd', homeFiat: 'MYR', status: LunoConnectionStatus.ok);
          });
          await h.pump(tester, size: const Size(1200, 1600));
          await tester.runAsync(() => h.container.read(refreshControllerProvider.notifier).refresh(force: true));
          expect(server.requests, isEmpty);
          await h.dispose(tester);
        });
      });
    });
  }
}
