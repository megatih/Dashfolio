import 'package:dio/dio.dart';

import '../../core/failure.dart';
import 'yahoo_config.dart';

/// Obtains and caches the Yahoo session cookie + crumb (native platforms only).
///
/// The [Dio] instance must have a cookie manager attached so the cookie from
/// `fc.yahoo.com` is sent with the crumb request.
class CrumbManager {
  CrumbManager(this._dio);

  final Dio _dio;
  String? _crumb;
  Future<String>? _pending;

  Future<String> get() {
    final cached = _crumb;
    if (cached != null) return Future.value(cached);
    return _pending ??= _fetch().whenComplete(() {
      _pending = null;
    });
  }

  void invalidate() => _crumb = null;

  Future<String> _fetch() async {
    final opts = Options(headers: {'User-Agent': YahooConfig.userAgent}, validateStatus: (_) => true, responseType: ResponseType.plain);
    try {
      // 1) Session cookie. The response is typically a 404; only the Set-Cookie matters.
      await _dio.get<String>('https://fc.yahoo.com', options: opts);
      // 2) Crumb tied to that cookie.
      final res = await _dio.get<String>('${YahooConfig.hosts.first}/v1/test/getcrumb', options: opts);
      final body = (res.data ?? '').trim();
      if (res.statusCode == 429) throw const RateLimitedFailure();
      if (res.statusCode != 200 || body.isEmpty || body.contains('<') || body.contains('Too Many')) {
        throw const UnauthorizedFailure('Could not obtain Yahoo crumb');
      }
      return _crumb = body;
    } on DioException {
      throw const NetworkFailure();
    }
  }
}
