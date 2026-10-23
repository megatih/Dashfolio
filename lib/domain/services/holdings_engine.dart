import 'package:decimal/decimal.dart';

import '../../core/decimal_ext.dart';
import '../entities/enums.dart';
import '../entities/portfolio.dart';

class Lot {
  Lot({required this.date, required this.quantity, required this.costLocal, required this.costBase});

  final DateTime date;
  Decimal quantity;

  /// Total cost of the remaining lot quantity in instrument currency (fees included).
  Decimal costLocal;

  /// Total cost of the remaining lot quantity in base currency (fees included).
  Decimal costBase;

  Decimal get unitCostLocal => quantity == Decimal.zero ? Decimal.zero : costLocal.div(quantity);
}

class Position {
  Position(this.symbol, this.currency);

  final String symbol;
  String currency;
  Decimal quantity = Decimal.zero;
  Decimal realizedBase = Decimal.zero;
  Decimal dividendsBase = Decimal.zero;
  DateTime? firstTradeDate;
  final List<Lot> lots = [];
  final List<String> warnings = [];

  Decimal get costLocal => lots.fold(Decimal.zero, (s, l) => s + l.costLocal);
  Decimal get costBase => lots.fold(Decimal.zero, (s, l) => s + l.costBase);
  Decimal get avgCostLocal => quantity == Decimal.zero ? Decimal.zero : costLocal.div(quantity);
  bool get isOpen => quantity > Decimal.zero;
}

class PortfolioPositions {
  PortfolioPositions(this.positions, this.cashBase, this.hasCashActivity, this.warnings);

  final Map<String, Position> positions;

  /// Cash balance in base currency derived from all transactions.
  final Decimal cashBase;
  final bool hasCashActivity;
  final List<String> warnings;

  Iterable<Position> get open => positions.values.where((p) => p.isOpen);
  Decimal get realizedBase => positions.values.fold(Decimal.zero, (s, p) => s + p.realizedBase);
  Decimal get dividendsBase => positions.values.fold(Decimal.zero, (s, p) => s + p.dividendsBase);
}

/// Replays transactions into positions using the given cost-basis method.
class HoldingsEngine {
  const HoldingsEngine();

  /// Total order: by date; then rows without an execution time (ranked so buys settle before sells), then rows with one
  /// (synced rows, in execution order).
  static int _compare(PortfolioTransaction a, PortfolioTransaction b) {
    final c = a.tradeDate.compareTo(b.tradeDate);
    if (c != 0) return c;
    final ag = a.executedAt == null ? 0 : 1;
    final bg = b.executedAt == null ? 0 : 1;
    if (ag != bg) return ag.compareTo(bg);
    if (ag == 1) {
      final e = a.executedAt!.compareTo(b.executedAt!);
      return e != 0 ? e : a.id.compareTo(b.id);
    }
    // Opening balances and buys settle before sells on the same day.
    final r = _rank(a.type).compareTo(_rank(b.type));
    if (r != 0) return r;
    final ca = a.createdAt.compareTo(b.createdAt);
    return ca != 0 ? ca : a.id.compareTo(b.id);
  }

  static int _rank(TxType t) => switch (t) {
    TxType.openingPosition => 0,
    TxType.deposit => 1,
    TxType.buy || TxType.transferIn || TxType.reward => 2,
    TxType.split => 3,
    TxType.dividend => 4,
    TxType.sell || TxType.transferOut => 5,
    TxType.withdrawal => 6,
    TxType.fee => 7,
  };

  /// Removes up to [quantity] from [p] (oldest lots first; the single lot under average cost) and returns the quantity
  /// actually removed with the base-currency cost that left the position.
  static ({Decimal removed, Decimal costBase}) _consume(Position p, Decimal quantity) {
    var remaining = quantity > p.quantity ? p.quantity : quantity;
    final removed = remaining;
    var costRemovedBase = Decimal.zero;
    while (remaining > Decimal.zero && p.lots.isNotEmpty) {
      final lot = p.lots.first;
      if (lot.quantity <= remaining) {
        costRemovedBase += lot.costBase;
        remaining -= lot.quantity;
        p.lots.removeAt(0);
      } else {
        final removedBase = (lot.costBase * remaining).div(lot.quantity);
        final removedLocal = (lot.costLocal * remaining).div(lot.quantity);
        lot
          ..quantity -= remaining
          ..costBase -= removedBase
          ..costLocal -= removedLocal;
        costRemovedBase += removedBase;
        remaining = Decimal.zero;
      }
    }
    p.quantity -= removed;
    if (p.quantity == Decimal.zero) p.lots.clear();
    return (removed: removed, costBase: costRemovedBase);
  }

  static void _addLot(Position p, CostMethod method, DateTime date, Decimal quantity, Decimal costLocal, Decimal costBase) {
    if (method == CostMethod.average && p.lots.isNotEmpty) {
      final lot = p.lots.first;
      lot.quantity += quantity;
      lot.costLocal += costLocal;
      lot.costBase += costBase;
    } else {
      p.lots.add(Lot(date: date, quantity: quantity, costLocal: costLocal, costBase: costBase));
    }
  }

  PortfolioPositions replay(Iterable<PortfolioTransaction> txs, CostMethod method, {DateTime? asOf}) {
    final sorted = txs.where((t) => asOf == null || !t.tradeDate.isAfter(asOf)).toList()..sort(_compare);
    final positions = <String, Position>{};
    final warnings = <String>[];
    var cash = Decimal.zero;
    var cashActivity = false;

    for (final t in sorted) {
      final fx = t.fxRateToBase;
      switch (t.type) {
        case TxType.deposit:
          cash += t.gross * fx;
          cashActivity = true;
        case TxType.withdrawal:
          cash -= t.gross * fx;
          cashActivity = true;
        case TxType.fee when t.symbol != null:
          // Fee paid in the asset itself (e.g. a crypto network fee): quantity leaves and its cost is a realized loss.
          final p = positions.putIfAbsent(t.symbol!, () => Position(t.symbol!, t.currency));
          final fee = _consume(p, t.quantity);
          p.realizedBase -= fee.costBase;
        case TxType.fee:
          cash -= t.gross * fx;
          cashActivity = true;
        case TxType.transferIn || TxType.reward:
          final p = positions.putIfAbsent(t.symbol!, () => Position(t.symbol!, t.currency));
          p.firstTradeDate ??= t.tradeDate;
          final costLocal = t.gross;
          final costBase = costLocal * fx;
          p.quantity += t.quantity;
          _addLot(p, method, t.tradeDate, t.quantity, costLocal, costBase);
          // Rewards are income received in kind; their cost basis is their value at receipt, so unrealized P&L excludes it.
          if (t.type == TxType.reward) p.dividendsBase += costBase;
        case TxType.transferOut:
          final p = positions.putIfAbsent(t.symbol!, () => Position(t.symbol!, t.currency));
          if (t.quantity > p.quantity) {
            p.warnings.add('Transfer out of ${t.quantity} on ${t.tradeDate.toIso8601String().substring(0, 10)} exceeds held ${p.quantity}');
            warnings.add('${t.symbol}: transfer out exceeds held quantity');
          }
          _consume(p, t.quantity); // moves cost with the asset: no realized P&L
          if (t.fees > Decimal.zero) {
            final fee = _consume(p, t.fees);
            p.realizedBase -= fee.costBase;
          }
        case TxType.buy || TxType.openingPosition:
          final p = positions.putIfAbsent(t.symbol!, () => Position(t.symbol!, t.currency));
          p.firstTradeDate ??= t.tradeDate;
          final fees = t.type == TxType.buy ? t.fees : Decimal.zero;
          final costLocal = t.gross + fees;
          final costBase = costLocal * fx;
          p.quantity += t.quantity;
          _addLot(p, method, t.tradeDate, t.quantity, costLocal, costBase);
          if (t.type == TxType.buy) cash -= costBase;
        case TxType.sell:
          final p = positions.putIfAbsent(t.symbol!, () => Position(t.symbol!, t.currency));
          var remaining = t.quantity;
          if (remaining > p.quantity) {
            p.warnings.add('Sell of ${t.quantity} on ${t.tradeDate.toIso8601String().substring(0, 10)} exceeds held ${p.quantity}');
            warnings.add('${t.symbol}: sell exceeds held quantity');
            remaining = p.quantity;
          }
          final sold = _consume(p, remaining);
          final soldQty = sold.removed;
          final costRemovedBase = sold.costBase;
          // Proceeds scale with the quantity actually sold.
          final scale = t.quantity == Decimal.zero ? Decimal.one : soldQty.div(t.quantity);
          final proceedsBase = (t.gross * scale - t.fees) * fx;
          p.realizedBase += proceedsBase - costRemovedBase;
          cash += proceedsBase;
        case TxType.dividend:
          final p = positions.putIfAbsent(t.symbol!, () => Position(t.symbol!, t.currency));
          final amount = t.quantity == Decimal.zero ? t.price : t.gross;
          final base = (amount - t.fees) * fx;
          p.dividendsBase += base;
          cash += base;
        case TxType.split:
          final p = positions[t.symbol!];
          if (p == null || t.price == Decimal.zero) continue;
          final ratio = t.quantity.div(t.price);
          p.quantity = p.quantity * ratio;
          for (final lot in p.lots) {
            lot.quantity = lot.quantity * ratio;
          }
      }
    }
    return PortfolioPositions(positions, cash, cashActivity, warnings);
  }

  /// Quantity of [symbol] held at the end of [date], from [txs].
  Decimal quantityAt(Iterable<PortfolioTransaction> txs, String symbol, DateTime date) {
    final r = replay(txs.where((t) => t.symbol == symbol), CostMethod.average, asOf: date);
    return r.positions[symbol]?.quantity ?? Decimal.zero;
  }
}
