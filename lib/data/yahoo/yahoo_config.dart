import 'package:flutter/foundation.dart';

/// Where requests are sent: Yahoo directly (native) or through a CORS proxy (web).
class YahooConfig {
  const YahooConfig({this.proxyBase, this.isWeb = kIsWeb});

  /// Proxy base URL (no trailing slash). When set, the proxy owns cookie/crumb handling.
  final String? proxyBase;

  /// Whether requests originate from a browser. Overridable so the web behavior can be tested natively.
  final bool isWeb;

  static const _envProxy = String.fromEnvironment('YAHOO_PROXY_URL');

  static String? _clean(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }

  /// Resolves the effective config from the compile-time define and an optional user override.
  factory YahooConfig.resolve({String? override}) => YahooConfig(proxyBase: _clean(override) ?? _clean(_envProxy));

  bool get viaProxy => proxyBase != null;

  /// Web cannot call Yahoo directly because of CORS.
  bool get misconfigured => isWeb && !viaProxy;

  static const hosts = ['https://query1.finance.yahoo.com', 'https://query2.finance.yahoo.com'];
  static const userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  String baseFor(int attempt) => proxyBase ?? hosts[attempt % hosts.length];
}
