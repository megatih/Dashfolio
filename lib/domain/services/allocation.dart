import 'package:decimal/decimal.dart';

import '../../core/decimal_ext.dart';
import '../entities/enums.dart';
import 'valuation.dart';

class AllocationSlice {
  const AllocationSlice(this.label, this.value, this.weight, {this.isOther = false});
  final String label;
  final Decimal value;
  final Decimal weight;
  final bool isOther;
}

class Allocation {
  const Allocation();

  static String assetClassLabel(String? quoteType) => switch (quoteType?.toUpperCase()) {
    'EQUITY' => 'Stocks',
    'ETF' => 'ETFs',
    'MUTUALFUND' => 'Mutual funds',
    'CRYPTOCURRENCY' => 'Crypto',
    'CURRENCY' => 'Currencies',
    'INDEX' => 'Indices',
    'FUTURE' => 'Futures',
    'OPTION' => 'Options',
    _ => 'Other',
  };

  String _key(HoldingValuation h, AllocationGroup g) {
    final q = h.quote;
    return switch (g) {
      AllocationGroup.holding => h.symbol,
      AllocationGroup.assetClass => assetClassLabel(q?.quoteType),
      AllocationGroup.sector =>
        (q?.sector?.isNotEmpty ?? false) ? q!.sector! : (q?.quoteType == 'EQUITY' ? 'Unknown' : assetClassLabel(q?.quoteType)),
      AllocationGroup.currency => h.currency,
      AllocationGroup.exchange => q?.exchange ?? 'Unknown',
    };
  }

  /// Groups [holdings] and returns slices sorted by value (desc) with weights summing to 1.
  List<AllocationSlice> group(List<HoldingValuation> holdings, AllocationGroup g) {
    final sums = <String, Decimal>{};
    for (final h in holdings) {
      if (h.marketValueBase <= Decimal.zero) continue;
      sums.update(_key(h, g), (v) => v + h.marketValueBase, ifAbsent: () => h.marketValueBase);
    }
    final total = sums.values.fold(Decimal.zero, (s, v) => s + v);
    if (total == Decimal.zero) return const [];
    final slices = sums.entries.map((e) => AllocationSlice(e.key, e.value, e.value.div(total))).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return slices;
  }

  /// Collapses slices below [threshold] (ratio) into a single "Other" slice for charts.
  List<AllocationSlice> collapseSmall(List<AllocationSlice> slices, {double threshold = 0.02}) {
    final t = dec(threshold);
    final big = slices.where((s) => s.weight >= t).toList();
    final small = slices.where((s) => s.weight < t).toList();
    if (small.length < 2) return slices;
    final value = small.fold(Decimal.zero, (s, e) => s + e.value);
    final weight = small.fold(Decimal.zero, (s, e) => s + e.weight);
    return [...big, AllocationSlice('Other', value, weight, isOther: true)];
  }
}
