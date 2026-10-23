import 'package:decimal/decimal.dart';

import '../../core/clock.dart';
import '../../core/decimal_ext.dart';
import '../entities/enums.dart';
import '../entities/luno.dart';
import '../entities/portfolio.dart';

/// Price of one unit of [asset] in the connection's home fiat at [at], or null when unknown.
typedef FiatPrice = Decimal? Function(String asset, DateTime at);

/// Rate converting one unit of [currency] to the app's base currency at [at].
typedef FxToBase = Decimal Function(String currency, DateTime at);

class LunoMapContext {
  const LunoMapContext({
    required this.portfolioId,
    required this.connectionId,
    required this.homeFiat,
    required this.now,
    required this.priceOf,
    required this.fxToBase,
    this.settleWindow = const Duration(minutes: 10),
  });

  final int portfolioId;
  final int connectionId;
  final String homeFiat;
  final DateTime now;
  final FiatPrice priceOf;
  final FxToBase fxToBase;

  /// A trade leg without a counterpart younger than this is assumed to be in flight (the other account has not been
  /// fetched yet) and is retried on the next sync; older ones are reported as unrecognised.
  final Duration settleWindow;
}

class LunoMapResult {
  const LunoMapResult({
    required this.transactions,
    required this.mapped,
    required this.unrecognised,
    required this.deferred,
    required this.warnings,
  });

  final List<PortfolioTransaction> transactions;

  /// Ledger rows (by [LunoLedgerEntry.externalId]) that are now represented by [transactions].
  final Set<String> mapped;

  /// Rows that could not be interpreted, with the reason. They are surfaced to the user, never booked.
  final Map<String, String> unrecognised;

  /// Rows to try again later (counterpart not fetched yet, or no fiat price available yet).
  final Set<String> deferred;
  final List<String> warnings;
}

/// Turns Luno account-ledger rows into portfolio transactions.
///
/// The ledger is the source of truth: every movement of every account is a row. Rows that belong together share a
/// `reference` (a withdrawal and its network fee, the fee of a trade). The two legs of a trade live in *different*
/// accounts and are paired by `reference` + trade sequence. Fees are taken from the ledger's own FEE rows, so cash
/// and quantities replay exactly to the account balances; whatever the ledger already netted into an amount stays
/// embedded in the derived price (the cost basis therefore includes it).
class LunoLedgerMapper {
  const LunoLedgerMapper();

  static int _order(LunoLedgerEntry a, LunoLedgerEntry b) {
    final t = a.timestamp.compareTo(b.timestamp);
    if (t != 0) return t;
    final acct = a.accountId.compareTo(b.accountId);
    return acct != 0 ? acct : a.rowIndex.compareTo(b.rowIndex);
  }

  LunoMapResult map(Iterable<LunoLedgerEntry> entries, LunoMapContext ctx) {
    final rows = entries.toList()..sort(_order);
    final out = <PortfolioTransaction>[];
    final mapped = <String>{};
    final unrecognised = <String, String>{};
    final deferred = <String>{};
    final warnings = <String>[];
    final consumed = <String>{};

    final feesByRef = <String, List<LunoLedgerEntry>>{};
    for (final e in rows.where((e) => e.kind == LunoLedgerKind.fee && e.reference.isNotEmpty)) {
      feesByRef.putIfAbsent(e.reference, () => []).add(e);
    }

    /// Fee rows of the same operation in [asset] that no one has claimed yet.
    List<LunoLedgerEntry> claimFees(String reference, String asset) {
      if (reference.isEmpty) return const [];
      final fees = [
        for (final f in feesByRef[reference] ?? const <LunoLedgerEntry>[])
          if (!consumed.contains(f.externalId) && f.asset == asset && f.balanceDelta < Decimal.zero) f,
      ];
      consumed.addAll(fees.map((f) => f.externalId));
      mapped.addAll(fees.map((f) => f.externalId));
      return fees;
    }

    PortfolioTransaction tx({
      required TxType type,
      String? symbol,
      required Decimal quantity,
      required Decimal price,
      Decimal? fees,
      required String currency,
      required DateTime at,
      required String externalId,
      String? notes,
    }) => PortfolioTransaction(
      id: 0,
      portfolioId: ctx.portfolioId,
      symbol: symbol,
      type: type,
      tradeDate: dateOnly(at.toUtc()),
      quantity: quantity,
      price: price,
      fees: fees ?? Decimal.zero,
      currency: currency,
      fxRateToBase: ctx.fxToBase(currency, at),
      notes: notes,
      createdAt: ctx.now,
      source: TxSource.luno,
      connectionId: ctx.connectionId,
      externalId: externalId,
      executedAt: at.toUtc(),
    );

    String homeSymbol(String asset) => lunoSymbol('$asset${ctx.homeFiat}');

    /// Rate converting [fiat] into the home fiat on the day of [at] (both are valued against the base currency).
    Decimal toHome(String fiat, DateTime at) {
      if (fiat == ctx.homeFiat) return Decimal.one;
      final fromBase = ctx.fxToBase(fiat, at);
      final homeBase = ctx.fxToBase(ctx.homeFiat, at);
      return homeBase == Decimal.zero ? Decimal.one : fromBase.div(homeBase);
    }

    void reject(Iterable<LunoLedgerEntry> group, String reason) {
      for (final e in group) {
        unrecognised[e.externalId] = reason;
        consumed.add(e.externalId);
      }
    }

    void defer(Iterable<LunoLedgerEntry> group, String? warning) {
      for (final e in group) {
        deferred.add(e.externalId);
        consumed.add(e.externalId);
      }
      if (warning != null) warnings.add(warning);
    }

    void book(Iterable<LunoLedgerEntry> group, PortfolioTransaction t) {
      out.add(t);
      for (final e in group) {
        mapped.add(e.externalId);
        consumed.add(e.externalId);
      }
    }

    // ---- 1. trades: pair the legs of each exchange operation -------------------------------------------------------
    final exchangeGroups = <String, List<LunoLedgerEntry>>{};
    for (final e in rows.where((e) => e.kind == LunoLedgerKind.exchange)) {
      final key = e.reference.isEmpty ? e.externalId : '${e.reference}|${e.tradeSequence ?? ''}';
      exchangeGroups.putIfAbsent(key, () => []).add(e);
    }
    for (final g in exchangeGroups.values) {
      if (g.length == 1) {
        final age = ctx.now.difference(g.first.timestamp);
        age < ctx.settleWindow ? defer(g, null) : reject(g, 'Trade leg without a counterpart');
        continue;
      }
      if (g.length != 2 || g[0].accountId == g[1].accountId) {
        reject(g, 'Unexpected trade shape (${g.length} rows)');
        continue;
      }
      final legs = [...g]..sort((a, b) => a.accountId.compareTo(b.accountId));
      final a = legs[0], b = legs[1];
      final pair = a.tradePair ?? b.tradePair;
      LunoLedgerEntry? base, counter;
      if (pair == '${a.asset}${b.asset}') {
        (base, counter) = (a, b);
      } else if (pair == '${b.asset}${a.asset}') {
        (base, counter) = (b, a);
      } else {
        final fiatLegs = legs.where((l) => isLunoFiat(l.asset)).toList();
        if (fiatLegs.length == 1) {
          counter = fiatLegs.single;
          base = legs.firstWhere((l) => l != counter);
        }
      }
      if (base == null || counter == null || isLunoFiat(base.asset)) {
        reject(g, 'Could not tell the base and counter assets of the trade');
        continue;
      }
      final baseQty = base.balanceDelta.abs();
      final counterQty = counter.balanceDelta.abs();
      if (baseQty == Decimal.zero || counterQty == Decimal.zero || base.balanceDelta.sign == counter.balanceDelta.sign) {
        reject(g, 'Trade legs do not offset each other');
        continue;
      }
      final isBuy = base.balanceDelta > Decimal.zero;
      final at = base.timestamp;
      final id = '${a.externalId}+${b.externalId}';

      if (isLunoFiat(counter.asset)) {
        // One position per asset: a trade paid in another fiat is expressed in the home fiat at that day's rate, so the
        // same coin never ends up in two positions that a later transfer or fee could not draw down.
        final k = toHome(counter.asset, at);
        final fiatFees = claimFees(base.reference, counter.asset).fold(Decimal.zero, (s, f) => s + f.balanceDelta.abs());
        // Luno charges its fee in the traded coin: out of what you receive on a buy, on top of what you sell on a sell.
        // Either way the coins that really changed hands are |leg + fee|, and the fiat amount is spread over all of them,
        // so the fee is part of the cost basis (buy) or reduces the proceeds per coin (sell), never a stray transaction.
        final coinFee = claimFees(base.reference, base.asset).fold(Decimal.zero, (s, f) => s + f.balanceDelta);
        final qty = (base.balanceDelta + coinFee).abs();
        if (qty == Decimal.zero) {
          reject(g, 'Trade fee consumes the whole amount');
          continue;
        }
        final notes = [
          if (counter.asset != ctx.homeFiat) 'Paid in ${counter.asset}',
          if (coinFee != Decimal.zero) 'Includes fee of ${coinFee.abs()} ${base.asset}',
        ];
        book(
          g,
          tx(
            type: isBuy ? TxType.buy : TxType.sell,
            symbol: homeSymbol(base.asset),
            quantity: qty,
            price: (counterQty * k).div(qty),
            fees: fiatFees * k,
            currency: ctx.homeFiat,
            at: at,
            externalId: id,
            notes: notes.isEmpty ? null : notes.join('. '),
          ),
        );
        continue;
      }

      // Crypto for crypto: a sell of one asset and a buy of the other, both valued in the home fiat.
      final counterPrice = ctx.priceOf(counter.asset, at);
      final basePrice = ctx.priceOf(base.asset, at);
      final value = counterPrice != null ? counterQty * counterPrice : (basePrice != null ? baseQty * basePrice : null);
      if (value == null) {
        defer(g, 'No ${ctx.homeFiat} price for ${base.asset}/${counter.asset} on ${at.toIso8601String().substring(0, 10)}');
        continue;
      }
      out.add(
        tx(
          type: isBuy ? TxType.buy : TxType.sell,
          symbol: homeSymbol(base.asset),
          quantity: baseQty,
          price: value.div(baseQty),
          currency: ctx.homeFiat,
          at: at,
          externalId: id,
        ),
      );
      out.add(
        tx(
          type: isBuy ? TxType.sell : TxType.buy,
          symbol: homeSymbol(counter.asset),
          quantity: counterQty,
          price: value.div(counterQty),
          currency: ctx.homeFiat,
          at: at,
          externalId: '$id:counter',
        ),
      );
      for (final e in g) {
        mapped.add(e.externalId);
        consumed.add(e.externalId);
      }
    }

    // ---- 2. transfers ----------------------------------------------------------------------------------------------
    for (final e in rows.where((e) => e.kind == LunoLedgerKind.transfer && !consumed.contains(e.externalId))) {
      final inbound = e.balanceDelta > Decimal.zero;
      final amount = e.balanceDelta.abs();
      if (amount == Decimal.zero) {
        reject([e], 'Zero-amount transfer');
        continue;
      }
      if (isLunoFiat(e.asset)) {
        book(
          [e],
          tx(
            type: inbound ? TxType.deposit : TxType.withdrawal,
            quantity: Decimal.one,
            price: amount,
            currency: e.asset,
            at: e.timestamp,
            externalId: e.externalId,
          ),
        );
        continue;
      }
      final price = ctx.priceOf(e.asset, e.timestamp);
      if (inbound && price == null) {
        defer([e], 'No ${ctx.homeFiat} price for ${e.asset} on ${e.timestamp.toIso8601String().substring(0, 10)}');
        continue;
      }
      final fees = inbound ? Decimal.zero : claimFees(e.reference, e.asset).fold(Decimal.zero, (s, f) => s + f.balanceDelta.abs());
      book(
        [e],
        tx(
          type: inbound ? TxType.transferIn : TxType.transferOut,
          symbol: homeSymbol(e.asset),
          quantity: amount,
          price: price ?? Decimal.zero,
          fees: fees,
          currency: ctx.homeFiat,
          at: e.timestamp,
          externalId: e.externalId,
          notes: e.txId == null ? null : 'On-chain transaction ${e.txId}',
        ),
      );
    }

    // ---- 3. interest -----------------------------------------------------------------------------------------------
    for (final e in rows.where((e) => e.kind == LunoLedgerKind.interest && !consumed.contains(e.externalId))) {
      if (e.balanceDelta <= Decimal.zero) {
        reject([e], 'Negative or zero interest');
      } else if (isLunoFiat(e.asset)) {
        book(
          [e],
          tx(
            type: TxType.deposit,
            quantity: Decimal.one,
            price: e.balanceDelta,
            currency: e.asset,
            at: e.timestamp,
            externalId: e.externalId,
            notes: 'Interest',
          ),
        );
      } else {
        final price = ctx.priceOf(e.asset, e.timestamp);
        if (price == null) {
          defer([e], 'No ${ctx.homeFiat} price for ${e.asset} on ${e.timestamp.toIso8601String().substring(0, 10)}');
          continue;
        }
        book(
          [e],
          tx(
            type: TxType.reward,
            symbol: homeSymbol(e.asset),
            quantity: e.balanceDelta,
            price: price,
            currency: ctx.homeFiat,
            at: e.timestamp,
            externalId: e.externalId,
            notes: 'Interest',
          ),
        );
      }
    }

    // ---- 4. fees nobody claimed, and everything else -----------------------------------------------------------------
    for (final e in rows.where((e) => !consumed.contains(e.externalId))) {
      if (e.kind == LunoLedgerKind.unknown && e.balanceDelta == Decimal.zero) {
        // Order bookkeeping ("Reserved funds for order", "Released funds for order"): funds move between available and
        // reserved but the balance, and therefore the holding, does not change.
        mapped.add(e.externalId);
      } else if (e.kind != LunoLedgerKind.fee) {
        reject([e], 'Unknown ledger entry type');
      } else if (e.balanceDelta >= Decimal.zero) {
        reject([e], 'Fee refund');
      } else if (isLunoFiat(e.asset)) {
        book(
          [e],
          tx(
            type: TxType.fee,
            quantity: Decimal.one,
            price: e.balanceDelta.abs(),
            currency: e.asset,
            at: e.timestamp,
            externalId: e.externalId,
          ),
        );
      } else {
        book(
          [e],
          tx(
            type: TxType.fee,
            symbol: homeSymbol(e.asset),
            quantity: e.balanceDelta.abs(),
            price: ctx.priceOf(e.asset, e.timestamp) ?? Decimal.zero,
            currency: ctx.homeFiat,
            at: e.timestamp,
            externalId: e.externalId,
          ),
        );
      }
    }

    out.sort((a, b) => a.executedAt!.compareTo(b.executedAt!));
    return LunoMapResult(transactions: out, mapped: mapped, unrecognised: unrecognised, deferred: deferred, warnings: warnings);
  }
}
