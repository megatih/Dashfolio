/// A Luno API key id and secret. [toString] is redacted so a stray log line cannot leak them.
class LunoCredentials {
  const LunoCredentials({required this.keyId, required this.keySecret});

  final String keyId;
  final String keySecret;

  /// Last four characters of the key id: the only fragment ever persisted outside the secure store.
  String get keyIdHint => keyId.length <= 4 ? keyId : keyId.substring(keyId.length - 4);

  @override
  String toString() => 'LunoCredentials(***)';
}
