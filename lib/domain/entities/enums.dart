enum CostMethod {
  average,
  fifo;

  static CostMethod parse(String? v) => CostMethod.values.firstWhere((e) => e.name == v, orElse: () => CostMethod.average);

  String get label => switch (this) {
    CostMethod.average => 'Average cost',
    CostMethod.fifo => 'FIFO',
  };
}

enum TxType {
  buy,
  sell,
  dividend,
  split,
  deposit,
  withdrawal,
  fee,
  openingPosition,
  transferIn,
  transferOut,
  reward;

  static TxType parse(String? v) => TxType.values.firstWhere((e) => e.dbName == v, orElse: () => TxType.buy);

  String get dbName => switch (this) {
    TxType.openingPosition => 'opening_position',
    TxType.transferIn => 'transfer_in',
    TxType.transferOut => 'transfer_out',
    _ => name,
  };

  String get label => switch (this) {
    TxType.buy => 'Buy',
    TxType.sell => 'Sell',
    TxType.dividend => 'Dividend',
    TxType.split => 'Split',
    TxType.deposit => 'Deposit',
    TxType.withdrawal => 'Withdrawal',
    TxType.fee => 'Fee',
    TxType.openingPosition => 'Opening position',
    TxType.transferIn => 'Transfer in',
    TxType.transferOut => 'Transfer out',
    TxType.reward => 'Reward',
  };

  /// Whether the transaction concerns a security (needs a symbol).
  bool get hasSymbol => switch (this) {
    TxType.deposit || TxType.withdrawal || TxType.fee => false,
    _ => true,
  };
}

/// Where a transaction came from. `luno` rows are written only by the Luno sync service and are read-only in the UI.
enum TxSource {
  manual,
  csv,
  luno;

  static TxSource parse(String? v) => TxSource.values.firstWhere((e) => e.name == v, orElse: () => TxSource.manual);
}

enum ChartRange {
  d1('1D', '1d', '5m'),
  d5('5D', '5d', '15m'),
  m1('1M', '1mo', '1d'),
  m3('3M', '3mo', '1d'),
  m6('6M', '6mo', '1d'),
  ytd('YTD', 'ytd', '1d'),
  y1('1Y', '1y', '1d'),
  y5('5Y', '5y', '1wk'),
  max('MAX', 'max', '1mo');

  const ChartRange(this.label, this.yahooRange, this.interval);
  final String label;
  final String yahooRange;
  final String interval;

  bool get intraday => this == d1 || this == d5;

  /// Start date of the range relative to [now] (null for MAX).
  DateTime? start(DateTime now) => switch (this) {
    ChartRange.d1 => now.subtract(const Duration(days: 1)),
    ChartRange.d5 => now.subtract(const Duration(days: 5)),
    ChartRange.m1 => DateTime(now.year, now.month - 1, now.day),
    ChartRange.m3 => DateTime(now.year, now.month - 3, now.day),
    ChartRange.m6 => DateTime(now.year, now.month - 6, now.day),
    ChartRange.ytd => DateTime(now.year, 1, 1),
    ChartRange.y1 => DateTime(now.year - 1, now.month, now.day),
    ChartRange.y5 => DateTime(now.year - 5, now.month, now.day),
    ChartRange.max => null,
  };
}

/// Portfolio dashboard history ranges.
enum HistoryRange {
  w1('1W'),
  m1('1M'),
  m3('3M'),
  ytd('YTD'),
  y1('1Y'),
  y5('5Y'),
  max('MAX');

  const HistoryRange(this.label);
  final String label;

  DateTime? start(DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    return switch (this) {
      HistoryRange.w1 => today.subtract(const Duration(days: 7)),
      HistoryRange.m1 => DateTime.utc(today.year, today.month - 1, today.day),
      HistoryRange.m3 => DateTime.utc(today.year, today.month - 3, today.day),
      HistoryRange.ytd => DateTime.utc(today.year, 1, 1),
      HistoryRange.y1 => DateTime.utc(today.year - 1, today.month, today.day),
      HistoryRange.y5 => DateTime.utc(today.year - 5, today.month, today.day),
      HistoryRange.max => null,
    };
  }
}

enum AllocationGroup {
  holding('Holding'),
  assetClass('Asset class'),
  sector('Sector'),
  currency('Currency'),
  exchange('Exchange');

  const AllocationGroup(this.label);
  final String label;
}
