import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../design_system/app/app_ui.dart';
import '../design_system/gallery.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/holdings/holding_detail_screen.dart';
import '../features/import_export/import_screen.dart';
import '../features/income/income_screen.dart';
import '../features/lock/lock_controller.dart';
import '../features/lock/lock_screen.dart';
import '../features/luno/luno_connect_screen.dart';
import '../features/luno/luno_connection_screen.dart';
import '../features/luno/luno_connections_screen.dart';
import '../features/markets/markets_screen.dart';
import '../features/markets/quote_screen.dart';
import '../features/portfolios/portfolio_detail_screen.dart';
import '../features/portfolios/portfolios_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/welcome_screen.dart';
import '../features/shell/app_shell.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Redirect logic, extracted so it can be unit tested.
String? appRedirect({
  required String location,
  required bool settingsLoaded,
  required bool lockReady,
  required bool locked,
  required bool disclaimerAccepted,
}) {
  if (!settingsLoaded || !lockReady) return null; // the app root shows a splash meanwhile
  if (locked) return location == Routes.lock ? null : Routes.lock;
  if (location == Routes.lock) return Routes.dashboard;
  if (!disclaimerAccepted) return location == Routes.welcome ? null : Routes.welcome;
  if (location == Routes.welcome || location == '/') return Routes.dashboard;
  return null;
}

/// Notifies go_router to re-run redirects when lock or onboarding state changes.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(lockControllerProvider, (_, _) => refresh.ping());
  ref.listen(appSettingsProvider.select((s) => (s.loaded, s.disclaimerAccepted)), (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(appSettingsProvider);
      final lock = ref.read(lockControllerProvider);
      return appRedirect(
        location: state.matchedLocation,
        settingsLoaded: settings.loaded,
        lockReady: lock.ready,
        locked: lock.locked,
        disclaimerAccepted: settings.disclaimerAccepted,
      );
    },
    errorBuilder: (context, state) => AppScaffold(
      body: AppPage(
        title: 'Page not found',
        scrollable: false,
        padBody: false,
        child: Center(
          child: AppTextButton(label: 'Back to dashboard', onPressed: () => context.go(Routes.dashboard)),
        ),
      ),
    ),
    routes: [
      GoRoute(path: Routes.lock, builder: (_, _) => const LockScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      if (kDebugMode) GoRoute(path: Routes.gallery, builder: (_, _) => const DesignGallery()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.dashboard, builder: (_, _) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.portfolios,
                builder: (_, _) => const PortfoliosScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => PortfolioDetailScreen(portfolioId: int.tryParse(s.pathParameters['id'] ?? '') ?? -1),
                    routes: [
                      GoRoute(
                        path: 'holdings/:symbol',
                        builder: (_, s) => HoldingDetailScreen(
                          portfolioId: int.tryParse(s.pathParameters['id'] ?? '') ?? -1,
                          symbol: s.pathParameters['symbol'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.markets,
                builder: (_, _) => const MarketsScreen(),
                routes: [
                  GoRoute(
                    path: 'quote/:symbol',
                    builder: (_, s) => QuoteScreen(symbol: s.pathParameters['symbol'] ?? ''),
                  ),
                  GoRoute(
                    path: 'watchlists/:id',
                    builder: (_, s) => MarketsScreen(watchlistId: int.tryParse(s.pathParameters['id'] ?? '')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.income, builder: (_, _) => const IncomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(path: 'import', builder: (_, _) => const ImportScreen()),
                  // Luno is native-only: a browser cannot call its API, and keys must not live in a browser store.
                  GoRoute(
                    path: 'luno',
                    redirect: (_, _) => ref.read(lunoSupportedProvider) ? null : Routes.settings,
                    builder: (_, _) => const LunoConnectionsScreen(),
                    routes: [
                      GoRoute(path: 'connect', builder: (_, _) => const LunoConnectScreen()),
                      GoRoute(
                        path: ':id',
                        builder: (_, s) => LunoConnectionScreen(connectionId: int.tryParse(s.pathParameters['id'] ?? '') ?? -1),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Placeholder shown while settings/lock state load.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppScaffold(
    body: Center(child: SizedBox(width: 280, child: AppCardSkeleton(height: 120, lines: 2))),
  );
}
