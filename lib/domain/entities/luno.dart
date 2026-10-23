import 'package:decimal/decimal.dart';

/// Luno account (wallet) balance. Amounts are in the account's [asset].
class LunoAccount {
  const LunoAccount({
    required this.accountId,
    required this.asset,
    this.accountType = '',
    this.name = '',
    required this.balance,
    required this.reserved,
    required this.unconfirmed,
  });

  final String accountId;
  final String asset;
  final String accountType;
  final String name;

  /// Amount available to send or trade.
  final Decimal balance;

  /// Locked by Luno (open orders, pending withdrawals).
  final Decimal reserved;

  /// Awaiting confirmation; not yet part of the ledger-derived holding.
  final Decimal unconfirmed;

  /// What the ledger-replayed quantity must equal: available plus reserved.
  Decimal get total => balance + reserved;
}

enum LunoLedgerKind {
  fee,
  transfer,
  exchange,
  interest,
  unknown;

  static LunoLedgerKind parse(String? v) => switch (v) {
    'FEE' => fee,
    'TRANSFER' => transfer,
    'EXCHANGE' => exchange,
    'INTEREST' => interest,
    _ => unknown,
  };
}

/// One row of an account's append-only ledger (`GET /accounts/{id}/transactions`).
class LunoLedgerEntry {
  const LunoLedgerEntry({
    required this.accountId,
    required this.rowIndex,
    required this.timestamp,
    required this.asset,
    required this.kind,
    required this.balanceDelta,
    this.availableDelta,
    this.balance,
    this.description = '',
    this.reference = '',
    this.tradePair,
    this.tradePrice,
    this.tradeVolume,
    this.tradeSequence,
    this.txId,
  });

  final String accountId;
  final int rowIndex;
  final DateTime timestamp;
  final String asset;
  final LunoLedgerKind kind;

  /// Signed change of the account balance.
  final Decimal balanceDelta;
  final Decimal? availableDelta;
  final Decimal? balance;
  final String description;

  /// Shared by every entry belonging to one operation (both legs of a trade, a withdrawal and its fee, ...).
  final String reference;

  /// `detail_fields.trade_details` for exchange entries.
  final String? tradePair;
  final Decimal? tradePrice;
  final Decimal? tradeVolume;
  final int? tradeSequence;

  /// `detail_fields.crypto_details.txid` for on-chain movements.
  final String? txId;

  String get externalId => '$accountId:$rowIndex';
}

/// A fill of one of the user's orders (`GET /listtrades`).
class LunoTrade {
  const LunoTrade({
    required this.tradeId,
    required this.orderId,
    required this.pair,
    required this.timestamp,
    required this.isBuy,
    required this.price,
    required this.base,
    required this.counter,
    required this.feeBase,
    required this.feeCounter,
    this.sequence,
  });

  final String tradeId;
  final String orderId;
  final String pair;
  final DateTime timestamp;

  /// True when the *user's side* bought base (the order's type was BID).
  final bool isBuy;
  final Decimal price;
  final Decimal base;
  final Decimal counter;
  final Decimal feeBase;
  final Decimal feeCounter;
  final int? sequence;
}

/// A confirmed credit or debit (`GET /exchange/1/transfers`). [amount] is always positive.
class LunoTransfer {
  const LunoTransfer({
    required this.id,
    required this.createdAt,
    required this.amount,
    required this.fee,
    required this.inbound,
    this.transactionId,
  });

  final String id;
  final DateTime createdAt;
  final Decimal amount;
  final Decimal fee;
  final bool inbound;
  final String? transactionId;
}

enum LunoMarketStatus {
  active,
  postOnly,
  disabled,
  unknown;

  static LunoMarketStatus parse(String? v) => switch (v) {
    'ACTIVE' => active,
    'POSTONLY' || 'POST_ONLY' => postOnly,
    'DISABLED' || 'SUSPENDED' => disabled,
    _ => unknown,
  };
}

class LunoTicker {
  const LunoTicker({required this.pair, this.bid, this.ask, this.lastTrade, this.volume24h, required this.status, required this.timestamp});

  final String pair;
  final Decimal? bid;
  final Decimal? ask;
  final Decimal? lastTrade;
  final Decimal? volume24h;
  final LunoMarketStatus status;
  final DateTime timestamp;
}

class LunoMarket {
  const LunoMarket({
    required this.pair,
    required this.base,
    required this.counter,
    required this.priceScale,
    required this.volumeScale,
    required this.status,
  });

  final String pair;
  final String base;
  final String counter;
  final int priceScale;
  final int volumeScale;
  final LunoMarketStatus status;
}

class LunoCandle {
  const LunoCandle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime timestamp;
  final Decimal open;
  final Decimal high;
  final Decimal low;
  final Decimal close;
  final Decimal volume;
}

/// Seconds per candle accepted by `GET /exchange/1/candles`.
const lunoCandleDurations = [60, 300, 900, 1800, 3600, 10800, 14400, 28800, 86400, 259200, 604800];

/// Symbol prefix routing market data to Luno.
const lunoSymbolPrefix = 'LUNO:';

bool isLunoSymbol(String symbol) => symbol.startsWith(lunoSymbolPrefix);

String lunoSymbol(String pair) => '$lunoSymbolPrefix$pair';

String lunoPairOf(String symbol) => symbol.substring(lunoSymbolPrefix.length);

/// Luno's code for Bitcoin is `XBT`; Yahoo uses `BTC`.
String yahooAssetCode(String lunoAsset) => lunoAsset == 'XBT' ? 'BTC' : lunoAsset;

const _assetNames = {
  'XBT': 'Bitcoin',
  'ETH': 'Ethereum',
  'XRP': 'Ripple',
  'LTC': 'Litecoin',
  'BCH': 'Bitcoin Cash',
  'USDC': 'USD Coin',
  'USDT': 'Tether',
  'SOL': 'Solana',
  'ADA': 'Cardano',
  'DOGE': 'Dogecoin',
  'DOT': 'Polkadot',
  'LINK': 'Chainlink',
  'MATIC': 'Polygon',
  'AVAX': 'Avalanche',
  'ATOM': 'Cosmos',
  'XLM': 'Stellar',
  'UNI': 'Uniswap',
  'AAVE': 'Aave',
  'ALGO': 'Algorand',
  'CRV': 'Curve',
  'FTM': 'Fantom',
  'GRT': 'The Graph',
  'MKR': 'Maker',
  'NEAR': 'Near Protocol',
  'SAND': 'The Sandbox',
  'SNX': 'Synthetix',
  'TRX': 'Tron',
};

String lunoAssetName(String asset) => _assetNames[asset] ?? asset;

const lunoFiatCurrencies = {'AUD', 'EUR', 'GBP', 'IDR', 'MYR', 'NGN', 'UGX', 'ZAR', 'ZMW', 'KES', 'NAD', 'SGD', 'USD'};

bool isLunoFiat(String asset) => lunoFiatCurrencies.contains(asset);

enum LunoConnectionStatus {
  ok,
  syncing,
  error,
  revoked,
  credentialsMissing,
  needsReview;

  String get dbName => switch (this) {
    credentialsMissing => 'credentials_missing',
    needsReview => 'needs_review',
    _ => name,
  };

  static LunoConnectionStatus parse(String? v) =>
      LunoConnectionStatus.values.firstWhere((e) => e.dbName == v, orElse: () => LunoConnectionStatus.credentialsMissing);

  String get label => switch (this) {
    ok => 'Synced',
    syncing => 'Syncing…',
    error => 'Sync failed',
    revoked => 'Key revoked',
    credentialsMissing => 'Key needed',
    needsReview => 'Needs review',
  };

  /// Whether a sync may be attempted.
  bool get canSync => this == ok || this == error || this == needsReview || this == syncing;
}

/// A Luno API key and the synced portfolio it feeds. Credentials live only in the secure store.
class LunoConnection {
  const LunoConnection({
    required this.id,
    required this.label,
    required this.portfolioId,
    this.keyIdHint = '',
    required this.homeFiat,
    this.status = LunoConnectionStatus.credentialsMissing,
    this.lastSyncAt,
    this.lastError,
    this.writePermWarning = false,
    this.unrecognisedRows = 0,
    required this.createdAt,
  });

  final int id;
  final String label;
  final int portfolioId;
  final String keyIdHint;
  final String homeFiat;
  final LunoConnectionStatus status;
  final DateTime? lastSyncAt;
  final String? lastError;
  final bool writePermWarning;
  final int unrecognisedRows;
  final DateTime createdAt;

  LunoConnection copyWith({
    String? label,
    String? keyIdHint,
    String? homeFiat,
    LunoConnectionStatus? status,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
    bool? writePermWarning,
    int? unrecognisedRows,
  }) => LunoConnection(
    id: id,
    label: label ?? this.label,
    portfolioId: portfolioId,
    keyIdHint: keyIdHint ?? this.keyIdHint,
    homeFiat: homeFiat ?? this.homeFiat,
    status: status ?? this.status,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastError: clearError ? null : (lastError ?? this.lastError),
    writePermWarning: writePermWarning ?? this.writePermWarning,
    unrecognisedRows: unrecognisedRows ?? this.unrecognisedRows,
    createdAt: createdAt,
  );
}

/// How far an account's ledger has been synced and the balances seen then.
class LunoAccountCursor {
  const LunoAccountCursor({
    required this.connectionId,
    required this.accountId,
    required this.asset,
    this.accountType = '',
    this.lastRowIndex = 0,
    required this.balanceSnapshot,
    required this.reservedSnapshot,
    required this.unconfirmedSnapshot,
    this.syncedAt,
  });

  final int connectionId;
  final String accountId;
  final String asset;
  final String accountType;
  final int lastRowIndex;
  final Decimal balanceSnapshot;
  final Decimal reservedSnapshot;
  final Decimal unconfirmedSnapshot;
  final DateTime? syncedAt;

  /// True when [a] reports exactly the balances recorded at the last sync.
  bool matches(LunoAccount a) => a.balance == balanceSnapshot && a.reserved == reservedSnapshot && a.unconfirmed == unconfirmedSnapshot;
}

/// Fee schedule and 30-day volume for a pair (`GET /fee_info`). Rates are fractions (0.001 = 0.1 %).
class LunoFeeInfo {
  const LunoFeeInfo({
    required this.makerFeeBuy,
    required this.makerFeeSell,
    required this.takerFeeBuy,
    required this.takerFeeSell,
    required this.thirtyDayVolume,
  });

  final Decimal makerFeeBuy;
  final Decimal makerFeeSell;
  final Decimal takerFeeBuy;
  final Decimal takerFeeSell;
  final Decimal thirtyDayVolume;
}
