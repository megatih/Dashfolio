import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/data/yahoo/yahoo_config.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/fake_market_data.dart';
import '../support/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<AppHarness> start(WidgetTester tester, YahooConfig config) async {
    final h = AppHarness.create();
    h.extraOverrides.add(yahooConfigProvider.overrideWithValue(config));
    await h.completeOnboarding();
    h.market.setQuote(fakeQuote('AAPL', price: 100));
    await tester.runAsync(() async {
      final repo = PortfolioRepositoryImpl(h.db, h.clock);
      final pid = await repo.createPortfolio(const NewPortfolio(name: 'P'));
      await repo.addTransaction(buy('AAPL', '2024-01-02', 1, 90, portfolio: pid));
    });
    await h.pump(tester);
    return h;
  }

  testWidgets('web build without a proxy shows setup guidance and still renders cached data', (tester) async {
    final h = await start(tester, const YahooConfig(isWeb: true));
    expect(find.textContaining('Prices need the Yahoo proxy on the web'), findsOneWidget);
    expect(find.text(r'$100.00'), findsWidgets); // cached quote still values the holding
    await h.dispose(tester);
  });

  testWidgets('no banner once a proxy is configured, or on native platforms', (tester) async {
    final h = await start(tester, const YahooConfig(isWeb: true, proxyBase: 'https://proxy.example'));
    expect(find.textContaining('Prices need the Yahoo proxy'), findsNothing);
    await h.dispose(tester);

    final n = await start(tester, const YahooConfig());
    expect(find.textContaining('Prices need the Yahoo proxy'), findsNothing);
    await n.dispose(tester);
  });
}
