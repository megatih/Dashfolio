import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/domain/services/fx.dart';
import 'package:dashfolio/features/settings/base_currency_rebaser.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/fake_market_data.dart';

void main() {
  late AppDatabase db;
  late PortfolioRepositoryImpl repo;
  late FakeMarketData market;
  late BaseCurrencyRebaser rebaser;
  late int pid;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = PortfolioRepositoryImpl(db, FixedClock(DateTime.utc(2024, 6, 1)));
    market = FakeMarketData();
    rebaser = BaseCurrencyRebaser(portfolios: repo, market: market);
    pid = await repo.createPortfolio(const NewPortfolio(name: 'P'));
  });
  tearDown(() => db.close());

  Future<Map<String, String>> rates() async => {
    for (final t in await repo.watchTransactions().first)
      '${t.symbol}@${t.tradeDate.toIso8601String().substring(0, 10)}': t.fxRateToBase.toString(),
  };

  test('same base is a no-op', () async {
    await repo.addTransaction(buy('A', '2024-01-02', 1, 1, portfolio: pid));
    final r = await rebaser.rebase(oldBase: 'USD', newBase: 'USD', currentFx: const IdentityFx());
    expect(r.updated, 0);
  });

  test('uses historical rates to the new base; base-currency rows become 1', () async {
    await repo.addTransactions([
      buy('AAPL', '2024-01-03', 1, 100, portfolio: pid), // USD, old base
      buy('SAP.DE', '2024-01-03', 1, 100, currency: 'EUR', fx: '1.1', portfolio: pid), // EUR is the new base
    ]);
    market.daily['USDEUR=X'] = fakeCandles('2024-01-01', [0.90, 0.91, 0.92, 0.93]);
    final r = await rebaser.rebase(oldBase: 'USD', newBase: 'EUR', currentFx: QuoteFxRates({'USDEUR=X': 0.95}));
    final m = await rates();
    expect(m['AAPL@2024-01-03'], '0.92');
    expect(m['SAP.DE@2024-01-03'], '1');
    expect(r.updated, 2);
    expect(r.fromHistory, 1);
  });

  test('falls back to old rate × current old→new rate when history is missing', () async {
    await repo.addTransaction(buy('SAP.DE', '2024-01-03', 1, 100, currency: 'GBP', fx: '1.25', portfolio: pid)); // GBP->USD = 1.25
    // No GBPEUR history; USD->EUR is 0.9 today => GBP->EUR ≈ 1.125
    final r = await rebaser.rebase(oldBase: 'USD', newBase: 'EUR', currentFx: QuoteFxRates({'USDEUR=X': 0.9}));
    expect((await rates())['SAP.DE@2024-01-03'], '1.125');
    expect(r.fromChain, 1);
    expect(r.unresolved, 0);
  });

  test('leaves rows unchanged when no rate can be determined', () async {
    await repo.addTransaction(buy('X', '2024-01-03', 1, 1, currency: 'GBP', fx: '1.25', portfolio: pid));
    final r = await rebaser.rebase(oldBase: 'USD', newBase: 'EUR', currentFx: const IdentityFx());
    expect(r.unresolved, 1);
    expect(r.updated, 0);
    expect((await rates())['X@2024-01-03'], '1.25');
    expect(describeRebase(r), contains('could not be converted'));
  });
}
