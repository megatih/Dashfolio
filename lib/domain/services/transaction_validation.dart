import 'package:decimal/decimal.dart';

import '../entities/enums.dart';
import '../entities/portfolio.dart';
import 'holdings_engine.dart';

/// Values entered in the transaction form (already parsed; null = empty/invalid number).
class TxDraft {
  const TxDraft({required this.type, this.symbol, required this.date, this.quantity, this.price, this.fees, this.fxRate});

  final TxType type;
  final String? symbol;
  final DateTime date;
  final Decimal? quantity;
  final Decimal? price;
  final Decimal? fees;
  final Decimal? fxRate;
}

/// Field-keyed validation messages (`symbol`, `date`, `quantity`, `price`, `fees`, `fx`).
class TxValidation {
  const TxValidation(this.errors);
  final Map<String, String> errors;
  bool get isValid => errors.isEmpty;
}

class TransactionValidator {
  const TransactionValidator({this.engine = const HoldingsEngine()});

  final HoldingsEngine engine;

  TxValidation validate(
    TxDraft d, {
    required List<PortfolioTransaction> existing,
    int? excludeId,
    required DateTime now,
    required CostMethod method,
  }) {
    final errors = <String, String>{};
    final today = DateTime.utc(now.year, now.month, now.day);

    if (d.type.hasSymbol && (d.symbol == null || d.symbol!.trim().isEmpty)) errors['symbol'] = 'Choose a symbol';
    if (d.date.isAfter(today)) errors['date'] = 'Date cannot be in the future';

    final cashOnly = !d.type.hasSymbol;
    final q = d.quantity, p = d.price;
    if (cashOnly) {
      if (p == null || p <= Decimal.zero) errors['price'] = 'Enter an amount greater than zero';
    } else {
      if (q == null || q <= Decimal.zero) {
        errors['quantity'] = d.type == TxType.split ? 'Enter the new share count' : 'Enter a quantity greater than zero';
      }
      switch (d.type) {
        case TxType.split:
          if (p == null || p <= Decimal.zero) errors['price'] = 'Enter the old share count';
        case TxType.dividend:
          if (p == null || p <= Decimal.zero) errors['price'] = 'Enter the dividend per share';
        case TxType.buy || TxType.sell || TxType.openingPosition || TxType.transferIn || TxType.transferOut || TxType.reward:
          if (p == null || p < Decimal.zero) errors['price'] = 'Enter a price (zero or more)';
        default:
          break;
      }
    }
    if (d.fees != null && d.fees! < Decimal.zero) errors['fees'] = 'Fees cannot be negative';
    if (d.fxRate == null || d.fxRate! <= Decimal.zero) errors['fx'] = 'Enter an exchange rate greater than zero';

    if ((d.type == TxType.sell || d.type == TxType.transferOut) && errors['quantity'] == null && errors['symbol'] == null && q != null) {
      final others = existing.where((t) => t.id != excludeId).toList();
      final held = engine.quantityAt(others.where((t) => t.symbol == d.symbol), d.symbol!, d.date);
      if (q > held) {
        errors['quantity'] = held <= Decimal.zero ? 'No shares held on this date' : 'Only ${held.toString()} shares held on this date';
      } else {
        // A sell dated earlier can starve a later sell; make sure the sequence stays valid.
        final before = engine.replay(others, method).warnings.length;
        final draft = PortfolioTransaction(
          id: -1,
          portfolioId: 0,
          symbol: d.symbol,
          type: d.type,
          tradeDate: d.date,
          quantity: q,
          price: p ?? Decimal.zero,
          fees: d.fees ?? Decimal.zero,
          currency: 'USD',
          fxRateToBase: Decimal.one,
          createdAt: now,
        );
        final after = engine.replay([...others, draft], method).warnings.length;
        if (after > before) errors['quantity'] = 'This would leave a later sell without enough shares';
      }
    }
    return TxValidation(errors);
  }

  /// Whether deleting [tx] would leave a sell without enough shares.
  bool deleteBreaksHistory(PortfolioTransaction tx, List<PortfolioTransaction> all, CostMethod method) {
    final before = engine.replay(all, method).warnings.length;
    final after = engine.replay(all.where((t) => t.id != tx.id), method).warnings.length;
    return after > before;
  }
}
