import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef Handler = ResponseBody Function(RequestOptions o);

/// Records every request and answers with [handler]; never touches the network.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  Handler handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}

  Iterable<RequestOptions> where(String method, [String? path]) =>
      requests.where((r) => r.method == method && (path == null || r.uri.path == path));
}

ResponseBody jsonBody(String text, [int status = 200, Map<String, List<String>> headers = const {}]) => ResponseBody.fromString(
  text,
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
    ...headers,
  },
);
