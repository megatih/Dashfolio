import 'dart:convert';

import 'package:dashfolio/app/app_settings.dart' show AppSkin;
import 'package:dashfolio/app/file_service.dart';
import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/routing/router.dart';
import 'package:dashfolio/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/fake_market_data.dart';
import '../support/fonts.dart';

const _csv = '''Trade Date,Ticker,Action,Shares,Price,Commission
2024-01-02,AAPL,Buy,10,150.25,1
2024-02-01,AAPL,Sell,4,160,0
2024-02-02,MSFT,Wire,1,1,0
2024-03-01,MSFT,Buy,2,400,0
''';

void main() {
  setUpAll(loadAppFonts);
  for (final skin in AppSkin.values) {
    group(skin.name, () {
      Future<AppHarness> start(WidgetTester tester) async {
        final h = AppHarness.create(skin: skin);
        await h.completeOnboarding();
        h.market.setQuote(fakeQuote('AAPL', price: 190));
        h.market.setQuote(fakeQuote('MSFT', price: 410));
        await tester.runAsync(() => PortfolioRepositoryImpl(h.db, h.clock).createPortfolio(const NewPortfolio(name: 'Broker')));
        await h.pump(tester);
        return h;
      }

      Future<List<PortfolioTransactionLike>> txs(WidgetTester tester, AppHarness h) async => (await tester.runAsync(
        () async => [
          for (final t in await h.container.read(portfolioRepositoryProvider).watchTransactions().first)
            PortfolioTransactionLike(t.symbol, t.type, t.quantity.toString(), t.price.toString(), t.importBatchId),
        ],
      ))!;

      testWidgets('import wizard: pick file, map columns, review, commit, undo', (tester) async {
        final h = await start(tester);
        h.files.toPick = const PickedText(name: 'broker.csv', text: _csv);
        h.container.read(routerProvider).go(Routes.importCsv);
        await h.settle(tester);

        expect(find.text('1. Choose a file'), findsOneWidget);
        await tester.tap(find.text('Choose CSV file…'));
        await h.settle(tester);

        // Columns were auto-detected from the headers.
        expect(find.text('2. Match columns'), findsOneWidget);
        expect(find.text('3 rows').evaluate().isEmpty, isTrue);
        expect(find.textContaining('4 rows'), findsOneWidget);
        await tester.tap(find.text('Preview'));
        await h.settle(tester);

        expect(find.text('3. Review'), findsOneWidget);
        expect(find.text('3 ready'), findsOneWidget);
        expect(find.text('1 with errors'), findsOneWidget);
        expect(find.textContaining('Unknown type "Wire"'), findsOneWidget);

        await tester.tap(find.text('Import 3 transactions'));
        await h.settle(tester, frames: 25);
        expect(find.text('Imported 3 transactions'), findsOneWidget);

        var saved = await txs(tester, h);
        expect(saved.length, 3);
        expect(saved.every((t) => t.batch != null), isTrue);
        expect(saved.map((t) => t.symbol).toSet(), {'AAPL', 'MSFT'});

        // Undo removes the whole batch.
        await tester.tap(find.text('Undo import'));
        await h.settle(tester);
        await tester.tap(find.text('Undo import').last);
        await h.settle(tester, frames: 20);
        saved = await txs(tester, h);
        expect(saved, isEmpty);
        await h.dispose(tester);
      });

      testWidgets('re-importing the same file flags duplicates and skips them by default', (tester) async {
        final h = await start(tester);
        await tester.runAsync(() async {
          final repo = PortfolioRepositoryImpl(h.db, h.clock);
          final pid = (await repo.watchPortfolios().first).single.id;
          await repo.addTransaction(buy('AAPL', '2024-01-02', '10', '150.25', fees: 1, portfolio: pid));
        });
        h.files.toPick = const PickedText(name: 'broker.csv', text: _csv);
        h.container.read(routerProvider).go(Routes.importCsv);
        await h.settle(tester);
        await tester.tap(find.text('Choose CSV file…'));
        await h.settle(tester);
        await tester.tap(find.text('Preview'));
        await h.settle(tester);

        expect(find.text('1 already imported'), findsOneWidget);
        expect(find.text('2 ready'), findsOneWidget);
        expect(find.text('Import 2 transactions'), findsOneWidget);
        await h.dispose(tester);
      });

      testWidgets('empty or headerless files show a friendly error', (tester) async {
        final h = await start(tester);
        h.files.toPick = const PickedText(name: 'empty.csv', text: 'Date,Symbol\n');
        h.container.read(routerProvider).go(Routes.importCsv);
        await h.settle(tester);
        await tester.tap(find.text('Choose CSV file…'));
        await h.settle(tester);
        expect(find.textContaining('has no data rows'), findsOneWidget);
        await h.dispose(tester);
      });

      testWidgets('settings: export a backup, wipe, then restore it (replace)', (tester) async {
        final h = await start(tester);
        await tester.runAsync(() async {
          final repo = PortfolioRepositoryImpl(h.db, h.clock);
          final pid = (await repo.watchPortfolios().first).single.id;
          await repo.addTransaction(buy('AAPL', '2024-01-02', 10, 150, portfolio: pid));
        });
        h.container.read(routerProvider).go(Routes.settings);
        await h.settle(tester);

        await tester.ensureVisible(find.text('Export backup (JSON)'));
        await tester.tap(find.text('Export backup (JSON)'));
        await h.settle(tester, frames: 20);
        final entry = h.files.saved.entries.firstWhere((e) => e.key.endsWith('.json'));
        final json = jsonDecode(entry.value) as Map<String, Object?>;
        expect(json['schema_version'], 2);
        expect((json['transactions']! as List).length, 1);

        await tester.ensureVisible(find.text('Export transactions (CSV)'));
        await tester.tap(find.text('Export transactions (CSV)'));
        await h.settle(tester, frames: 20);
        expect(h.files.saved.entries.firstWhere((e) => e.key.endsWith('.csv')).value, contains('AAPL'));

        // Wipe, then restore from the backup we just exported.
        await tester.runAsync(() => h.container.read(portfolioRepositoryProvider).wipeUserData());
        await h.settle(tester);
        h.files.toPick = PickedText(name: 'backup.json', text: entry.value);
        await tester.ensureVisible(find.text('Restore backup'));
        await tester.tap(find.text('Restore backup'));
        await h.settle(tester);
        expect(find.textContaining('1 portfolios · 1 transactions'), findsOneWidget);
        await tester.tap(find.text('Replace everything'));
        await h.settle(tester);
        await tester.tap(find.text('Replace').last);
        await h.settle(tester, frames: 25);

        final restored = await txs(tester, h);
        expect(restored.single.symbol, 'AAPL');
        expect(restored.single.quantity, '10');
        await h.dispose(tester);
      });

      testWidgets('restoring a non-backup file reports an error and changes nothing', (tester) async {
        final h = await start(tester);
        h.files.toPick = const PickedText(name: 'x.json', text: '{"hello": "world"}');
        h.container.read(routerProvider).go(Routes.settings);
        await h.settle(tester);
        await tester.ensureVisible(find.text('Restore backup'));
        await tester.tap(find.text('Restore backup'));
        await h.settle(tester);
        expect(find.textContaining('not a Dashfolio backup'), findsOneWidget);
        expect(find.text('Replace everything'), findsNothing);
        await h.dispose(tester);
      });

      testWidgets('settings: theme, base currency and lock controls render and persist', (tester) async {
        final h = await start(tester);
        h.container.read(routerProvider).go(Routes.settings);
        await h.settle(tester);
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Base currency'), findsOneWidget);
        expect(find.text('App lock'), findsOneWidget);

        await tester.tap(find.text('Dark'));
        await h.settle(tester);
        final saved = (await tester.runAsync(() => h.container.read(settingsRepositoryProvider).get('theme_mode')))!;
        expect(saved, 'dark');
        await h.dispose(tester);
      });
    });
  }
}

class PortfolioTransactionLike {
  PortfolioTransactionLike(this.symbol, this.type, this.quantity, this.price, this.batch);
  final String? symbol;
  final TxType type;
  final String quantity;
  final String price;
  final String? batch;
}
