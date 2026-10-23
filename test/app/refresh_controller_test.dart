import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/app/refresh_controller.dart';
import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/luno/luno_sync_service.dart';
import 'package:dashfolio/data/repositories/luno_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:drift/native.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dashfolio/domain/entities/portfolio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/fake_market_data.dart';

/// Records syncs and books one Luno transaction, standing in for the real sync service.
class _FakeSync extends LunoSyncService {
  _FakeSync(this.db, Clock clock, {this.failure})
    : super(
        luno: LunoRepositoryImpl(db),
        portfolios: PortfolioRepositoryImpl(db, clock),
        market: FakeMarketData(),
        clientFor: (_) => throw UnimplementedError(),
        clock: clock,
      );

  final AppDatabase db;
  final AppFailure? failure;
  final calls = <int>[];

  @override
  Future<LunoSyncResult> sync(
    int connectionId, {
    required String baseCurrency,
    void Function(LunoSyncProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    calls.add(connectionId);
    if (failure != null) return LunoSyncResult(failure: failure);
    final conn = (await LunoRepositoryImpl(db).getConnection(connectionId))!;
    await LunoRepositoryImpl(db).upsertSyncedTransactions(connectionId, [
      PortfolioTransaction(
        id: 0,
        portfolioId: conn.portfolioId,
        symbol: 'LUNO:XBTMYR',
        type: TxType.buy,
        tradeDate: DateTime.utc(2024, 1, 2),
        quantity: Decimal.one,
        price: Decimal.fromInt(100),
        fees: Decimal.zero,
        currency: 'MYR',
        fxRateToBase: Decimal.one,
        createdAt: clock.now(),
        source: TxSource.luno,
        connectionId: connectionId,
        externalId: 'x',
        executedAt: DateTime.utc(2024, 1, 2),
      ),
    ]);
    return const LunoSyncResult(transactions: 1);
  }
}

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late FakeMarketData market;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    clock = FixedClock(DateTime.utc(2024, 1, 10, 12));
    market = FakeMarketData();
    final repo = PortfolioRepositoryImpl(db, clock);
    final pid = await repo.createPortfolio(const NewPortfolio(name: 'Main'));
    await repo.addTransaction(buy('AAPL', '2024-01-02', 10, 150, portfolio: pid));
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        marketDataRepositoryProvider.overrideWithValue(market),
      ],
    );
    // Riverpod 3 pauses providers nobody listens to.
    for (final p in [portfoliosProvider, transactionsProvider, watchlistsProvider, quotesProvider, settingsMapProvider]) {
      container.listen(p, (_, _) {});
    }
    await container.read(transactionsProvider.future);
    await container.read(portfoliosProvider.future);
    await container.read(settingsMapProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

  test('a repeat refresh within the debounce window does not touch the network', () async {
    final controller = container.read(refreshControllerProvider.notifier);
    await controller.refresh();
    await settle();
    expect(market.refreshCalls.length, 1);

    clock.value = clock.value.add(const Duration(seconds: 10));
    await controller.refresh();
    expect(market.refreshCalls.length, 1);
    expect(container.read(refreshControllerProvider).throttledAt, clock.value);
  });

  test('after the debounce window the refresh runs again', () async {
    final controller = container.read(refreshControllerProvider.notifier);
    await controller.refresh();
    await settle();
    clock.value = clock.value.add(RefreshController.debounce + const Duration(seconds: 1));
    await controller.refresh();
    expect(market.refreshCalls.length, 2);
  });

  test('force bypasses the debounce (symbols or base currency changed)', () async {
    final controller = container.read(refreshControllerProvider.notifier);
    await controller.refresh();
    await settle();
    await controller.refresh(force: true);
    expect(market.refreshCalls.length, 2);
  });

  group('with Luno connections', () {
    late _FakeSync sync;

    Future<int> connect({LunoConnectionStatus status = LunoConnectionStatus.ok}) async {
      final pid = await PortfolioRepositoryImpl(db, clock).createPortfolio(const NewPortfolio(name: 'Luno'));
      return LunoRepositoryImpl(db).createConnection(label: 'L', portfolioId: pid, keyIdHint: 'abcd', homeFiat: 'MYR', status: status);
    }

    ProviderContainer make({AppFailure? failure}) {
      sync = _FakeSync(db, clock, failure: failure);
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
          marketDataRepositoryProvider.overrideWithValue(market),
          lunoSyncServiceProvider.overrideWithValue(sync),
        ],
      );
      for (final p in [settingsMapProvider]) {
        c.listen(p, (_, _) {});
      }
      addTearDown(c.dispose);
      return c;
    }

    test('syncs first, then refreshes prices for the symbols the sync produced', () async {
      final id = await connect();
      final c = make();
      await c.read(settingsMapProvider.future);
      await c.read(refreshControllerProvider.notifier).refresh(force: true);
      expect(sync.calls, [id]);
      expect(market.refreshCalls.any((s) => s.contains('LUNO:XBTMYR')), isTrue, reason: 'the synced holding is priced in the same refresh');
    });

    test('a failing Luno sync does not stop the price refresh, which then reads as partial', () async {
      await connect();
      final c = make(failure: const NetworkFailure());
      await c.read(settingsMapProvider.future);
      await c.read(refreshControllerProvider.notifier).refresh(force: true);
      expect(market.refreshCalls, isNotEmpty);
      final s = c.read(refreshControllerProvider);
      expect(s.partial, isTrue);
      expect(s.error, isNull);
      expect(s.running, isFalse);
    });

    test('connections that cannot sync (revoked or without a key) are not attempted', () async {
      await connect(status: LunoConnectionStatus.revoked);
      await connect(status: LunoConnectionStatus.credentialsMissing);
      final c = make();
      await c.read(settingsMapProvider.future);
      await c.read(refreshControllerProvider.notifier).refresh(force: true);
      expect(sync.calls, isEmpty);
    });

    test('with no connections the Luno step costs nothing', () async {
      final c = make();
      await c.read(settingsMapProvider.future);
      await c.read(refreshControllerProvider.notifier).refresh(force: true);
      expect(sync.calls, isEmpty);
      expect(market.refreshCalls.length, 1);
    });
  });
}
