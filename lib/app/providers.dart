import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../core/failure.dart';
import '../data/db/app_database.dart';
import '../data/luno/luno_client.dart';
import '../data/luno/luno_connect_service.dart';
import '../data/luno/luno_credential_store.dart';
import '../data/luno/luno_sync_service.dart';
import '../data/net/request_scheduler.dart';
import '../data/repositories/luno_market_data_repository.dart';
import '../data/repositories/luno_repository_impl.dart';
import '../data/repositories/market_data_repository_impl.dart';
import '../data/repositories/routing_market_data_repository.dart';
import '../data/repositories/portfolio_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/yahoo/crumb_manager.dart';
import '../data/yahoo/yahoo_client.dart';
import '../data/yahoo/yahoo_config.dart';
import '../domain/entities/luno.dart';
import '../domain/entities/market.dart';
import '../domain/entities/portfolio.dart';
import '../domain/repositories/luno_repository.dart';
import '../domain/repositories/market_data_repository.dart';
import '../domain/repositories/portfolio_repository.dart';
import '../domain/repositories/settings_repository.dart';
import 'app_settings.dart';

// ---- infrastructure ----------------------------------------------------------

/// Overridden in `main()` with the opened database.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider must be overridden'));

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepositoryImpl(ref.watch(databaseProvider)));

final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => PortfolioRepositoryImpl(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final yahooConfigProvider = Provider<YahooConfig>((ref) {
  final override = ref.watch(appSettingsProvider.select((s) => s.proxyUrlOverride));
  return YahooConfig.resolve(override: override);
});

final yahooClientProvider = Provider<YahooClient>((ref) {
  final config = ref.watch(yahooConfigProvider);
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));
  CrumbManager? crumb;
  if (!kIsWeb && !config.viaProxy) {
    dio.interceptors.add(CookieManager(CookieJar()));
    crumb = CrumbManager(dio);
  }
  return YahooClient(dio: dio, config: config, crumbManager: crumb, clock: ref.watch(clockProvider));
});

/// Yahoo Finance backed repository (also the fallback provider for Luno pairs).
final yahooMarketDataRepositoryProvider = Provider<MarketDataRepository>(
  (ref) => MarketDataRepositoryImpl(ref.watch(databaseProvider), ref.watch(yahooClientProvider), ref.watch(clockProvider)),
);

// ---- Luno (native platforms only) --------------------------------------------

/// Whether Luno can be used here. Browsers cannot call its API (no CORS) and must not hold API keys, so web is out.
/// A provider (rather than a bare `kIsWeb`) so the web behaviour can be tested.
final lunoSupportedProvider = Provider<bool>((ref) => !kIsWeb);

/// API credentials live only in the platform secure store.
final lunoCredentialStoreProvider = Provider<LunoCredentialStore>((ref) => SecureLunoCredentialStore());

final lunoRepositoryProvider = Provider<LunoRepository>((ref) => LunoRepositoryImpl(ref.watch(databaseProvider)));

final lunoConnectionsProvider = StreamProvider<List<LunoConnection>>((ref) => ref.watch(lunoRepositoryProvider).watchConnections());

/// One pacing budget for every Luno request (the documented limit is per API key; sharing is the conservative choice).
final lunoSchedulerProvider = Provider<RequestScheduler>((ref) {
  final s = RequestScheduler(name: 'luno', clock: ref.watch(clockProvider), limit: LunoClient.lunoRateLimit, maxConcurrent: 2);
  ref.onDispose(s.dispose);
  return s;
});

final lunoDioProvider = Provider<Dio>((ref) => Dio(BaseOptions(connectTimeout: const Duration(seconds: 15))));

/// A client authenticated as one connection; the secret is read from the secure store on every request.
final lunoClientFactoryProvider = Provider<LunoClientFactory>((ref) {
  final dio = ref.watch(lunoDioProvider);
  final store = ref.watch(lunoCredentialStoreProvider);
  final scheduler = ref.watch(lunoSchedulerProvider);
  return (connectionId) => LunoClient(
    dio: dio,
    scheduler: scheduler,
    credentials: () async => await store.read(connectionId) ?? (throw const CredentialsMissingFailure()),
  );
});

/// Client for market data: tickers and markets are public; candles borrow the key of any usable connection.
final lunoPublicClientProvider = Provider<LunoClient>((ref) {
  final store = ref.watch(lunoCredentialStoreProvider);
  final luno = ref.watch(lunoRepositoryProvider);
  return LunoClient(
    dio: ref.watch(lunoDioProvider),
    scheduler: ref.watch(lunoSchedulerProvider),
    credentials: () async {
      for (final c in await luno.getConnections()) {
        if (!c.status.canSync) continue;
        final creds = await store.read(c.id);
        if (creds != null) return creds;
      }
      throw const CredentialsMissingFailure();
    },
  );
});

final lunoMarketDataRepositoryProvider = Provider<LunoMarketDataRepository>(
  (ref) => LunoMarketDataRepository(
    ref.watch(databaseProvider),
    ref.watch(lunoPublicClientProvider),
    ref.watch(yahooMarketDataRepositoryProvider),
    ref.watch(clockProvider),
  ),
);

/// Market data for every symbol: Yahoo, plus Luno pairs on native platforms (Luno cannot be called from a browser).
final marketDataRepositoryProvider = Provider<MarketDataRepository>((ref) {
  final yahoo = ref.watch(yahooMarketDataRepositoryProvider);
  if (!ref.watch(lunoSupportedProvider)) return yahoo;
  return RoutingMarketDataRepository(primary: yahoo, luno: ref.watch(lunoMarketDataRepositoryProvider));
});

final lunoConnectServiceProvider = Provider<LunoConnectService>(
  (ref) => LunoConnectService(
    store: ref.watch(lunoCredentialStoreProvider),
    luno: ref.watch(lunoRepositoryProvider),
    portfolios: ref.watch(portfolioRepositoryProvider),
    dio: ref.watch(lunoDioProvider),
    scheduler: ref.watch(lunoSchedulerProvider),
  ),
);

/// Connection feeding each synced portfolio, by portfolio id. Synced portfolios are read-only in the UI.
final lunoConnectionByPortfolioProvider = Provider<Map<int, LunoConnection>>((ref) {
  final connections = ref.watch(lunoConnectionsProvider).value ?? const <LunoConnection>[];
  return {for (final c in connections) c.portfolioId: c};
});

final lunoSyncServiceProvider = Provider<LunoSyncService>(
  (ref) => LunoSyncService(
    luno: ref.watch(lunoRepositoryProvider),
    portfolios: ref.watch(portfolioRepositoryProvider),
    market: ref.watch(marketDataRepositoryProvider),
    clientFor: ref.watch(lunoClientFactoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

// ---- settings ----------------------------------------------------------------

final settingsMapProvider = StreamProvider<Map<String, String>>((ref) => ref.watch(settingsRepositoryProvider).watchAll());

/// Typed settings; falls back to defaults (with `loaded == false`) while the table is loading.
final appSettingsProvider = Provider<AppSettings>((ref) {
  final map = ref.watch(settingsMapProvider);
  return map.maybeWhen(data: AppSettings.fromMap, orElse: () => const AppSettings());
});

// ---- raw data streams ----------------------------------------------------------

final portfoliosProvider = StreamProvider<List<Portfolio>>((ref) => ref.watch(portfolioRepositoryProvider).watchPortfolios());

final transactionsProvider = StreamProvider<List<PortfolioTransaction>>(
  (ref) => ref.watch(portfolioRepositoryProvider).watchTransactions(),
);

final instrumentsProvider = StreamProvider<Map<String, Instrument>>((ref) => ref.watch(portfolioRepositoryProvider).watchInstruments());

final watchlistsProvider = StreamProvider<List<Watchlist>>((ref) => ref.watch(portfolioRepositoryProvider).watchWatchlists());

final importMappingsProvider = StreamProvider<List<ImportMapping>>((ref) => ref.watch(portfolioRepositoryProvider).watchImportMappings());

final quotesProvider = StreamProvider<Map<String, Quote>>((ref) => ref.watch(marketDataRepositoryProvider).watchQuotes());

final dividendEventsProvider = StreamProvider<Map<String, List<DividendEvent>>>(
  (ref) => ref.watch(marketDataRepositoryProvider).watchDividendEvents(),
);

final splitEventsProvider = StreamProvider<Map<String, List<SplitEvent>>>(
  (ref) => ref.watch(marketDataRepositoryProvider).watchSplitEvents(),
);

// ---- selection -----------------------------------------------------------------

/// Which portfolio the dashboard shows; `null` means "All portfolios".
class SelectedPortfolio extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

final selectedPortfolioProvider = NotifierProvider<SelectedPortfolio, int?>(SelectedPortfolio.new);
