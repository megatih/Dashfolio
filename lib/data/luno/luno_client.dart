import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/failure.dart';
import '../../domain/entities/luno.dart';
import '../net/request_scheduler.dart';
import 'luno_credentials.dart';
import 'luno_mappers.dart';

final _log = Logger('LunoClient');

/// Supplies credentials at the moment of each request; the client never holds them.
typedef LunoCredentialSource = Future<LunoCredentials> Function();

/// Raw outcome of a request, used by the permission probe, which needs the status and error code rather than a throw.
class LunoRawResponse {
  const LunoRawResponse(this.status, this.body);
  final int status;
  final Json? body;
  String get code => '${body?['code'] ?? ''}';
}

/// Read-only Luno REST client (https://api.luno.com).
///
/// Hardening: HTTPS to one allowlisted host only, no redirects, no logging of URLs, headers or bodies, HTTP Basic
/// credentials fetched per request from [credentials]. Pacing, retries, de-duplication and the circuit breaker come
/// from [RequestScheduler]. Every method here is a GET; the single generic [rawRequest] exists solely for
/// `LunoPermissionProbe` (a test enforces that nothing else calls it).
class LunoClient {
  LunoClient({required this.dio, required this.credentials, RequestScheduler? scheduler, this.maxAttempts = 3, this.backoff})
    : scheduler = scheduler ?? RequestScheduler(name: 'luno', limit: lunoRateLimit, maxConcurrent: 2);

  static const host = 'api.luno.com';
  static const baseUrl = 'https://$host';

  /// Luno documents 300 calls/minute per key; stay at 80 % of that (240/min = 4/s) with a small burst.
  static const lunoRateLimit = RateLimit(burst: 8, perSecond: 4);

  /// Max rows per ledger page and max trades/candles per call.
  static const pageSize = 1000;

  final Dio dio;
  final LunoCredentialSource credentials;
  final RequestScheduler scheduler;
  final int maxAttempts;

  /// Overrides the scheduler's jittered backoff (tests pass a no-op).
  final Future<void> Function(int attempt)? backoff;

  bool get circuitOpen => scheduler.circuitOpen;

  // ---- authenticated reads -------------------------------------------------

  Future<List<LunoAccount>> balances({RequestPriority priority = RequestPriority.refresh}) async =>
      LunoMappers.balances(await _get('/api/1/balance', const {}, auth: true, priority: priority));

  /// Ledger rows `[minRow, maxRow)`; row numbers start at 1 for the oldest entry.
  Future<List<LunoLedgerEntry>> ledger(String accountId, {required int minRow, required int maxRow}) async => LunoMappers.ledger(
    await _get('/api/1/accounts/${Uri.encodeComponent(accountId)}/transactions', {'min_row': '$minRow', 'max_row': '$maxRow'}, auth: true),
    accountId: accountId,
  );

  Future<List<LunoLedgerEntry>> pending(String accountId) async => LunoMappers.ledger(
    await _get('/api/1/accounts/${Uri.encodeComponent(accountId)}/pending', const {}, auth: true),
    key: 'pending',
    accountId: accountId,
  );

  /// The user's trades in [pair], oldest first, on or after [since].
  Future<List<LunoTrade>> trades(String pair, {DateTime? since, int limit = pageSize}) async => LunoMappers.trades(
    await _get('/api/1/listtrades', {
      'pair': pair,
      if (since != null) 'since': '${since.millisecondsSinceEpoch}',
      'limit': '$limit',
    }, auth: true),
  );

  /// Confirmed transfers for an account, newest first. Pass [before] (the oldest `created_at` seen) to page.
  Future<List<LunoTransfer>> transfers(String accountId, {DateTime? before, int limit = 100}) async => LunoMappers.transfers(
    await _get('/api/exchange/1/transfers', {
      'account_id': accountId,
      'limit': '$limit',
      if (before != null) 'before': '${before.millisecondsSinceEpoch}',
    }, auth: true),
  );

  Future<LunoFeeInfo> feeInfo(String pair) async =>
      lunoFeeInfo(await _get('/api/1/fee_info', {'pair': pair}, auth: true, priority: RequestPriority.lazy));

  /// Candles with `timestamp >= since`, oldest first, at most [pageSize]. The endpoint requires an API key.
  Future<List<LunoCandle>> candles(String pair, {required DateTime since, required int duration}) async {
    assert(lunoCandleDurations.contains(duration), 'unsupported candle duration $duration');
    return LunoMappers.candles(
      await _get('/api/exchange/1/candles', {
        'pair': pair,
        'since': '${since.millisecondsSinceEpoch}',
        'duration': '$duration',
      }, auth: true),
    );
  }

  // ---- public market data --------------------------------------------------

  /// All pairs when [pairs] is empty; otherwise one request with repeated `pair=` parameters.
  Future<List<LunoTicker>> tickers([Iterable<String> pairs = const []]) async =>
      LunoMappers.tickers(await _get('/api/1/tickers', {if (pairs.isNotEmpty) 'pair': pairs.toList()}, priority: RequestPriority.refresh));

  Future<List<LunoMarket>> markets({RequestPriority priority = RequestPriority.user}) async =>
      LunoMappers.markets(await _get('/api/exchange/1/markets', const {}, priority: priority));

  // ---- plumbing ------------------------------------------------------------

  Future<Json> _get(String path, Map<String, Object> query, {bool auth = false, RequestPriority priority = RequestPriority.refresh}) {
    final key = '$path?${(query.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}=${e.value}').join('&')}';
    return scheduler.dedupe(key, () async {
      final r = await _send('GET', path, query: query, auth: auth, priority: priority, retry: true);
      final status = r.status;
      if (status == 200 && r.body != null) {
        scheduler.recordSuccess();
        return r.body!;
      }
      throw lunoFailure(status, r.body);
    });
  }

  /// Sends one request without interpreting the status. Only `LunoPermissionProbe` may call this with a non-GET method.
  Future<LunoRawResponse> rawRequest(String method, String path, {Map<String, Object> query = const {}, Map<String, String>? form}) =>
      _send(method, path, query: query, form: form, auth: true, priority: RequestPriority.user, retry: false);

  Future<LunoRawResponse> _send(
    String method,
    String path, {
    Map<String, Object> query = const {},
    Map<String, String>? form,
    required bool auth,
    required RequestPriority priority,
    required bool retry,
  }) async {
    if (scheduler.circuitOpen) throw const RateLimitedFailure('Luno is rate limiting requests; try again shortly');
    final uri = Uri.parse('$baseUrl$path');
    if (uri.scheme != 'https' || uri.host != host) throw const NetworkFailure('Blocked request to an unexpected host');

    AppFailure last = const NetworkFailure();
    Duration? retryAfter;
    final attempts = retry ? maxAttempts : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final headers = <String, Object>{'Accept': 'application/json', 'User-Agent': 'Dashfolio'};
        if (auth) {
          final c = await credentials();
          headers['Authorization'] = 'Basic ${base64.encode(utf8.encode('${c.keyId}:${c.keySecret}'))}';
        }
        final res = await scheduler.schedule(
          () => dio.request<String>(
            uri.toString(),
            queryParameters: query.isEmpty ? null : query,
            data: form,
            options: Options(
              method: method,
              headers: headers,
              contentType: form == null ? null : Headers.formUrlEncodedContentType,
              responseType: ResponseType.plain,
              followRedirects: false,
              validateStatus: (_) => true,
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ),
          ),
          priority: priority,
        );
        final status = res.statusCode ?? 0;
        Json? body;
        try {
          body = decodeLunoJson(res.data ?? '');
        } on AppFailure {
          body = null;
        }
        if (status == 429) {
          last = const RateLimitedFailure('Luno is rate limiting requests');
          retryAfter = scheduler.parseRetryAfter(res.headers.value('retry-after'));
        } else if (status >= 500 || '${body?['code']}' == 'ErrClusterUnavailable') {
          last = const NetworkFailure('Luno is temporarily unavailable');
        } else {
          if (status >= 300 && status < 400) throw const NetworkFailure('Unexpected redirect from Luno');
          return LunoRawResponse(status, body);
        }
        _log.warning('HTTP $status for $path (attempt ${attempt + 1}/$attempts)');
      } on DioException catch (e) {
        // Never log the message, URI or headers: they can carry credentials.
        _log.warning('Network error for $path: ${e.type}');
        last = const NetworkFailure();
      }
      if (attempt < attempts - 1) {
        await (backoff?.call(attempt) ?? scheduler.sleepBackoff(attempt, retryAfter: retryAfter));
        retryAfter = null;
      }
    }
    if (last is RateLimitedFailure) scheduler.recordRateLimited();
    throw last;
  }
}
