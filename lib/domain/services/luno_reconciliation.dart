import 'package:decimal/decimal.dart';

import '../entities/luno.dart';

/// Quantity of one asset that differs between what Luno reports and what the replayed ledger yields.
class LunoAssetMismatch {
  const LunoAssetMismatch({required this.asset, required this.expected, required this.actual});

  final String asset;

  /// Luno's `balance + reserved` summed over the asset's accounts (`unconfirmed` is excluded).
  final Decimal expected;

  /// Quantity held according to the synced transactions.
  final Decimal actual;

  Decimal get delta => actual - expected;

  @override
  String toString() => '$asset: Luno reports $expected, synced history gives $actual';
}

/// The asset behind a `LUNO:{ASSET}{FIAT}` symbol (every Luno fiat code is three letters), or null for other symbols.
String? lunoSymbolAsset(String symbol) {
  if (!isLunoSymbol(symbol)) return null;
  final pair = lunoPairOf(symbol);
  return pair.length > 3 ? pair.substring(0, pair.length - 3) : null;
}

/// Compares Luno's account balances with the quantities the synced transactions replay to. Fiat wallets are not
/// compared (cash is derived in the base currency). A mismatch is reported, never silently adjusted.
List<LunoAssetMismatch> reconcileLuno({required Iterable<LunoAccount> accounts, required Map<String, Decimal> heldBySymbol}) {
  final expected = <String, Decimal>{};
  for (final a in accounts.where((a) => !isLunoFiat(a.asset))) {
    expected[a.asset] = (expected[a.asset] ?? Decimal.zero) + a.total;
  }
  final actual = <String, Decimal>{};
  heldBySymbol.forEach((symbol, qty) {
    final asset = lunoSymbolAsset(symbol);
    if (asset != null) actual[asset] = (actual[asset] ?? Decimal.zero) + qty;
  });
  return [
    for (final asset in {...expected.keys, ...actual.keys}.toList()..sort())
      if ((expected[asset] ?? Decimal.zero) != (actual[asset] ?? Decimal.zero))
        LunoAssetMismatch(asset: asset, expected: expected[asset] ?? Decimal.zero, actual: actual[asset] ?? Decimal.zero),
  ];
}
