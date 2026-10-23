import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/failure.dart';
import '../core/result.dart';
import '../domain/entities/portfolio.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/fx.dart';
import 'portfolio_providers.dart';
import 'providers.dart';

class RefreshState {
  const RefreshState({this.running = false, this.progress, this.error, this.partial = false, this.lastResultAt, this.throttledAt});

  final bool running;

  /// 0..1 while refreshing; null when idle.
  final double? progress;
  final AppFailure? error;
  final bool partial;
  final DateTime? lastResultAt;

  /// Set when a refresh request was skipped because data was refreshed moments ago.
  final DateTime? throttledAt;

  RefreshState copyWith({
    bool? running,
    double? progress,
    AppFailure? error,
    bool clearError = false,
    bool? partial,
    DateTime? lastResultAt,
    DateTime? throttledAt,
  }) => RefreshState(
    running: running ?? this.running,
    progress: progress,
    error: clearError ? null : (error ?? this.error),
    partial: partial ?? this.partial,
    lastResultAt: lastResultAt ?? this.lastResultAt,
    throttledAt: throttledAt ?? this.throttledAt,
  );
}

/// Orchestrates a manual refresh: quotes, FX, profiles and incremental daily history.
class RefreshController extends Notifier<RefreshState> {
  /// Data older than this is refreshed automatically when the app opens.
  static const staleAfter = Duration(minutes: 15);

  /// A manual refresh sooner than this after the previous completed one is skipped (nothing could have changed).
  static const debounce = Duration(seconds: 30);

  @override
  RefreshState build() => const RefreshState();

  bool get isStale {
    final last = ref.read(appSettingsProvider).lastRefreshAt;
    return last == null || ref.read(clockProvider).now().difference(last) > staleAfter;
  }

  Future<void> refreshIfStale() async {
    if (isStale) await refresh();
  }

  /// What the app currently tracks, read straight from the repositories so rows a Luno sync just wrote are included.
  Future<({Set<String> symbols, Set<String> held, List<PortfolioTransaction> transactions})> _collect() async {
    final portfolios = ref.read(portfolioRepositoryProvider);
    final active = {
      for (final p in await portfolios.getPortfolios())
        if (!p.archived) p.id,
    };
    final transactions = [
      for (final t in await portfolios.getTransactions())
        if (active.contains(t.portfolioId)) t,
    ];
    final held = symbolsFor(transactions);
    final watched = <String>{for (final w in await portfolios.getWatchlists()) ...w.symbols};
    final base = ref.read(appSettingsProvider).baseCurrency;
    final quotes = await ref.read(marketDataRepositoryProvider).quotesSnapshot();

    final currencies = <String>{
      for (final t in transactions) t.currency,
      for (final s in {...held, ...watched}) ?quotes[s]?.currency,
    }..remove(base);
    return (symbols: {...held, ...watched, for (final c in currencies) fxSymbol(c, base)}, held: held, transactions: transactions);
  }

  /// Syncs every Luno connection that can sync. Returns true if any of them failed (the refresh then reads as partial).
  Future<bool> _syncLuno(String baseCurrency) async {
    if (!ref.read(lunoSupportedProvider)) return false;
    final connections = await ref.read(lunoRepositoryProvider).getConnections();
    var failed = false;
    for (final c in connections.where((c) => c.status.canSync)) {
      final result = await ref.read(lunoSyncServiceProvider).sync(c.id, baseCurrency: baseCurrency);
      if (result.failure != null) failed = true;
    }
    return failed;
  }

  /// Refreshes prices, FX and history. A repeat request within [debounce] of the last completed refresh is skipped
  /// unless [force] is set (e.g. after the set of tracked symbols or the base currency changed).
  Future<void> refresh({bool force = false}) async {
    if (state.running) return;
    final repo = ref.read(marketDataRepositoryProvider);
    final clock = ref.read(clockProvider);
    final last = ref.read(appSettingsProvider).lastRefreshAt;
    if (!force && last != null && clock.now().difference(last) < debounce) {
      state = state.copyWith(throttledAt: clock.now());
      return;
    }
    state = const RefreshState(running: true, progress: 0.02);

    // Luno first: its sync decides which symbols are held. A Luno failure never blocks the price refresh.
    final lunoFailed = await _syncLuno(ref.read(appSettingsProvider).baseCurrency);
    final tracked = await _collect();
    final symbols = tracked.symbols;
    if (symbols.isEmpty) {
      await ref.read(settingsRepositoryProvider).set(SettingKeys.lastRefreshAt, clock.now().toIso8601String());
      state = RefreshState(partial: lunoFailed, lastResultAt: clock.now());
      return;
    }
    state = RefreshState(running: true, progress: 0.1, partial: lunoFailed);

    final quoteResult = await repo.refreshQuotes(symbols);
    switch (quoteResult) {
      case Err(:final failure):
        state = RefreshState(error: failure, lastResultAt: clock.now());
        return;
      case Ok(:final value):
        state = RefreshState(running: true, progress: 0.35, partial: value.partial || lunoFailed);
    }

    // Post-quote work is best effort; failures degrade gracefully to cached data.
    final held = tracked.held;
    final transactions = tracked.transactions;

    // Profiles (sector / beta) for held securities still lacking them.
    final quotes = (await repo.quotesSnapshot());
    final needProfile = held.where((s) => quotes[s]?.sector == null && (quotes[s]?.quoteType == 'EQUITY'));
    await mapPool(needProfile, 3, (String s) => repo.profile(s));
    state = state.copyWith(running: true, progress: 0.6);

    // Incremental daily history (also brings dividend/split events up to date).
    final firstTrade = transactions.isEmpty ? clock.now() : transactions.map((t) => t.tradeDate).reduce((a, b) => a.isBefore(b) ? a : b);
    final histSymbols = {...held, ...symbols.where((s) => s.endsWith('=X'))};
    var done = 0;
    await mapPool(histSymbols, 4, (String s) async {
      await repo.dailyHistory(s, firstTrade);
      done++;
      state = state.copyWith(running: true, progress: 0.6 + 0.38 * done / histSymbols.length, partial: state.partial);
    });

    await ref.read(settingsRepositoryProvider).set(SettingKeys.lastRefreshAt, clock.now().toIso8601String());
    ref.invalidate(valueHistoryProvider);
    state = RefreshState(partial: state.partial, lastResultAt: clock.now());
  }
}

final refreshControllerProvider = NotifierProvider<RefreshController, RefreshState>(RefreshController.new);
