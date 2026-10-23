import '../entities/enums.dart';
import '../entities/portfolio.dart';

class NewPortfolio {
  const NewPortfolio({required this.name, this.description, this.color = 0xFF3B82F6, this.costMethod = CostMethod.average});
  final String name;
  final String? description;
  final int color;
  final CostMethod costMethod;
}

abstract class PortfolioRepository {
  Stream<List<Portfolio>> watchPortfolios();

  /// One-shot snapshots for services that read state once (backup, imports, rebasing).
  Future<List<Portfolio>> getPortfolios();
  Future<List<PortfolioTransaction>> getTransactions();
  Future<List<Watchlist>> getWatchlists();
  Future<Map<String, Instrument>> getInstruments();

  Future<int> createPortfolio(NewPortfolio p);
  Future<void> updatePortfolio(Portfolio p);
  Future<void> deletePortfolio(int id);
  Future<void> reorderPortfolios(List<int> orderedIds);

  Stream<List<PortfolioTransaction>> watchTransactions();
  Future<int> addTransaction(PortfolioTransaction t);
  Future<void> addTransactions(List<PortfolioTransaction> txs);
  Future<void> updateTransaction(PortfolioTransaction t);
  Future<void> deleteTransaction(int id);

  /// Deletes every transaction created by an import batch; returns the count removed.
  Future<int> deleteImportBatch(String batchId);

  Stream<Map<String, Instrument>> watchInstruments();
  Future<void> upsertInstrument(Instrument i);

  Stream<List<Watchlist>> watchWatchlists();
  Future<int> createWatchlist(String name);
  Future<void> renameWatchlist(int id, String name);
  Future<void> deleteWatchlist(int id);
  Future<void> addToWatchlist(int id, String symbol);
  Future<void> removeFromWatchlist(int id, String symbol);
  Future<void> reorderWatchlistItems(int id, List<String> orderedSymbols);

  Stream<List<ImportMapping>> watchImportMappings();
  Future<void> saveImportMapping(String name, Map<String, Object?> mapping);
  Future<void> deleteImportMapping(int id);

  /// Removes all user data (portfolios, transactions, watchlists, instruments, mappings).
  Future<void> wipeUserData();
}

class ImportMapping {
  const ImportMapping({required this.id, required this.name, required this.mapping});
  final int id;
  final String name;
  final Map<String, Object?> mapping;
}
