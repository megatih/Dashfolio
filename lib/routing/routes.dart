/// Path constants for go_router.
abstract final class Routes {
  static const dashboard = '/dashboard';
  static const portfolios = '/portfolios';
  static const markets = '/markets';
  static const income = '/income';
  static const settings = '/settings';
  static const importCsv = '/settings/import';
  static const luno = '/settings/luno';
  static const lunoConnect = '/settings/luno/connect';
  static const lock = '/lock';
  static const welcome = '/welcome';
  static const gallery = '/gallery';

  static String lunoConnection(int id) => '/settings/luno/$id';
  static String portfolio(int id) => '/portfolios/$id';
  static String holding(int portfolioId, String symbol) => '/portfolios/$portfolioId/holdings/${Uri.encodeComponent(symbol)}';
  static String quote(String symbol) => '/markets/quote/${Uri.encodeComponent(symbol)}';
  static String watchlist(int id) => '/markets/watchlists/$id';
}
