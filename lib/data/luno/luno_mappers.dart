import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../../core/decimal_ext.dart';
import '../../core/failure.dart';
import '../../domain/entities/luno.dart';

typedef Json = Map<String, Object?>;

/// Ledger amounts (`balance`, `balance_delta`, `available`, `available_delta`) are JSON *numbers*, not strings.
/// Quote their literals before decoding so they reach [Decimal] without passing through a double.
final _numericLedgerField = RegExp(
  r'("(?:balance|balance_delta|available|available_delta)"\s*:\s*)(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)(?=\s*[,}])',
);

Json decodeLunoJson(String body) {
  try {
    final v = jsonDecode(body.replaceAllMapped(_numericLedgerField, (m) => '${m[1]}"${m[2]}"'));
    if (v is Json) return v;
  } on FormatException {
    // fall through
  }
  throw const ParseFailure('Luno response was not a JSON object');
}

/// Luno error codes (`{"code": "ErrX", "message": "..."}`) mapped to typed failures.
AppFailure lunoFailure(int status, Json? body) {
  final code = '${body?['code'] ?? ''}';
  final message = '${body?['message'] ?? ''}';
  if (status == 401 || code == 'ErrApiKeyRevoked') return const KeyRevokedFailure();
  if (code == 'ErrInsufficientPerms' || status == 403) return const ForbiddenFailure();
  if (status == 429) return const RateLimitedFailure('Luno is rate limiting requests');
  if (status == 404 ||
      const {'ErrNotFound', 'ErrAccountNotFound', 'ErrMarketUnavailable', 'ErrOrderNotFound', 'ErrWithdrawalNotFound'}.contains(code)) {
    return NotFoundFailure(message.isEmpty ? 'Not found' : message);
  }
  if (status >= 500 || code == 'ErrClusterUnavailable') return const NetworkFailure('Luno is temporarily unavailable');
  return NetworkFailure(message.isEmpty ? 'Unexpected response ($status)' : message);
}

abstract final class LunoMappers {
  static Decimal _d(Object? v) => decOrNull(v) ?? Decimal.zero;

  static DateTime _ms(Object? v) => DateTime.fromMillisecondsSinceEpoch(v is num ? v.toInt() : int.tryParse('$v') ?? 0, isUtc: true);

  static List<Json> _list(Json body, String key) => [if (body[key] is List) ...(body[key]! as List).whereType<Json>()];

  static List<LunoAccount> balances(Json body) => [
    for (final j in _list(body, 'balance'))
      LunoAccount(
        accountId: '${j['account_id'] ?? ''}',
        asset: '${j['asset'] ?? ''}',
        accountType: '${j['account_type'] ?? ''}',
        name: '${j['name'] ?? ''}',
        balance: _d(j['balance']),
        reserved: _d(j['reserved']),
        unconfirmed: _d(j['unconfirmed']),
      ),
  ];

  /// Ledger rows from `transactions` (or `pending` for the pending endpoint).
  static List<LunoLedgerEntry> ledger(Json body, {String key = 'transactions', String? accountId}) {
    final fallbackAccount = accountId ?? '${body['id'] ?? ''}';
    final out = <LunoLedgerEntry>[];
    for (final j in _list(body, key)) {
      final rowIndex = j['row_index'];
      if (rowIndex is! num) continue; // pending rows have none; they are shown, never booked
      final fields = j['detail_fields'] is Json ? j['detail_fields']! as Json : const <String, Object?>{};
      final trade = fields['trade_details'] is Json ? fields['trade_details']! as Json : const <String, Object?>{};
      final crypto = fields['crypto_details'] is Json ? fields['crypto_details']! as Json : const <String, Object?>{};
      final account = '${j['account_id'] ?? ''}';
      out.add(
        LunoLedgerEntry(
          accountId: account.isEmpty ? fallbackAccount : account,
          rowIndex: rowIndex.toInt(),
          timestamp: _ms(j['timestamp']),
          asset: '${j['currency'] ?? ''}',
          kind: LunoLedgerKind.parse(j['kind'] as String?),
          balanceDelta: _d(j['balance_delta']),
          availableDelta: decOrNull(j['available_delta']),
          balance: decOrNull(j['balance']),
          description: '${j['description'] ?? ''}',
          reference: '${j['reference'] ?? ''}',
          tradePair: trade['pair'] as String?,
          tradePrice: decOrNull(trade['price']),
          tradeVolume: decOrNull(trade['volume']),
          tradeSequence: (trade['sequence'] as num?)?.toInt(),
          txId: (crypto['txid'] as String?)?.isEmpty ?? true ? null : crypto['txid'] as String?,
        ),
      );
    }
    return out;
  }

  /// `type` is the side of the *user's* order that took part in the trade (BID = the user bought base).
  static List<LunoTrade> trades(Json body) => [
    for (final j in _list(body, 'trades'))
      LunoTrade(
        tradeId: '${j['trade_id'] ?? j['sequence'] ?? ''}',
        orderId: '${j['order_id'] ?? ''}',
        pair: '${j['pair'] ?? ''}',
        timestamp: _ms(j['timestamp']),
        isBuy: j['type'] == 'BID',
        price: _d(j['price']),
        base: _d(j['base']),
        counter: _d(j['counter']),
        feeBase: _d(j['fee_base']),
        feeCounter: _d(j['fee_counter']),
        sequence: (j['sequence'] as num?)?.toInt(),
      ),
  ];

  static List<LunoTransfer> transfers(Json body) => [
    for (final j in _list(body, 'transfers'))
      LunoTransfer(
        id: '${j['id'] ?? ''}',
        createdAt: _ms(j['created_at']),
        amount: _d(j['amount']).abs(),
        fee: _d(j['fee']),
        inbound: j['inbound'] == true,
        transactionId: (j['transaction_id'] as String?)?.isEmpty ?? true ? null : j['transaction_id'] as String?,
      ),
  ];

  static List<LunoTicker> tickers(Json body) => [
    for (final j in _list(body, 'tickers'))
      LunoTicker(
        pair: '${j['pair'] ?? ''}',
        bid: decOrNull(j['bid']),
        ask: decOrNull(j['ask']),
        lastTrade: decOrNull(j['last_trade']),
        volume24h: decOrNull(j['rolling_24_hour_volume']),
        status: LunoMarketStatus.parse(j['status'] as String?),
        timestamp: _ms(j['timestamp']),
      ),
  ];

  static List<LunoMarket> markets(Json body) => [
    for (final j in _list(body, 'markets'))
      LunoMarket(
        pair: '${j['market_id'] ?? ''}',
        base: '${j['base_currency'] ?? ''}',
        counter: '${j['counter_currency'] ?? ''}',
        priceScale: (j['price_scale'] as num?)?.toInt() ?? 0,
        volumeScale: (j['volume_scale'] as num?)?.toInt() ?? 0,
        status: LunoMarketStatus.parse(j['trading_status'] as String?),
      ),
  ];

  static List<LunoCandle> candles(Json body) => [
    for (final j in _list(body, 'candles'))
      LunoCandle(
        timestamp: _ms(j['timestamp']),
        open: _d(j['open']),
        high: _d(j['high']),
        low: _d(j['low']),
        close: _d(j['close']),
        volume: _d(j['volume']),
      ),
  ];
}

LunoFeeInfo lunoFeeInfo(Json body) {
  Decimal d(Object? v) => decOrNull(v) ?? Decimal.zero;
  final maker = body['maker_fee'];
  final taker = body['taker_fee'];
  return LunoFeeInfo(
    makerFeeBuy: d(body['maker_fee_buy'] ?? maker),
    makerFeeSell: d(body['maker_fee_sell'] ?? maker),
    takerFeeBuy: d(body['taker_fee_buy'] ?? taker),
    takerFeeSell: d(body['taker_fee_sell'] ?? taker),
    thirtyDayVolume: d(body['thirty_day_volume']),
  );
}
