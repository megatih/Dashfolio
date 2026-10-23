import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/failure.dart';
import 'luno_credentials.dart';

export 'luno_credentials.dart';

/// Where API credentials live. Implementations must use the platform secure store and nothing else:
/// when it is unavailable they throw [SecureStorageUnavailableFailure] rather than fall back to a weaker place.
abstract class LunoCredentialStore {
  /// Null when nothing is stored for [connectionId].
  Future<LunoCredentials?> read(int connectionId);

  Future<void> write(int connectionId, LunoCredentials credentials);

  Future<void> delete(int connectionId);

  /// Removes every Luno secret (app reset, disabling the app lock).
  Future<void> deleteAll();

  /// Whether the secure store can be used at all (false on web, or Linux without a Secret Service).
  Future<bool> isAvailable();
}

/// Secure-store backed credentials.
///
/// - iOS: keychain, `unlocked_this_device`, not synchronizable (no iCloud Keychain, not restored onto another device).
/// - macOS: the legacy file-based login keychain, matching the PIN store; the Data Protection keychain needs a signed
///   build with a keychain access group (see SPEC §7B).
/// - Windows: per-user DPAPI-protected storage. Linux: libsecret (Secret Service).
class SecureLunoCredentialStore implements LunoCredentialStore {
  SecureLunoCredentialStore([FlutterSecureStorage? storage]) : _s = storage ?? defaultStorage;

  static const defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device, synchronizable: false),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
      usesDataProtectionKeychain: false,
    ),
  );

  final FlutterSecureStorage _s;

  static const _prefix = 'dashfolio.luno.';
  static String _idKey(int id) => '$_prefix$id.keyId';
  static String _secretKey(int id) => '$_prefix$id.secret';

  Future<T> _guard<T>(Future<T> Function() body) async {
    if (kIsWeb) throw const SecureStorageUnavailableFailure('Luno is not available on web');
    try {
      return await body();
    } on PlatformException {
      throw const SecureStorageUnavailableFailure();
    } on UnsupportedError {
      throw const SecureStorageUnavailableFailure();
    }
  }

  @override
  Future<LunoCredentials?> read(int connectionId) => _guard(() async {
    final id = await _s.read(key: _idKey(connectionId));
    final secret = await _s.read(key: _secretKey(connectionId));
    if (id == null || secret == null) return null;
    return LunoCredentials(keyId: id, keySecret: secret);
  });

  @override
  Future<void> write(int connectionId, LunoCredentials credentials) => _guard(() async {
    await _s.write(key: _idKey(connectionId), value: credentials.keyId);
    await _s.write(key: _secretKey(connectionId), value: credentials.keySecret);
  });

  @override
  Future<void> delete(int connectionId) => _guard(() async {
    await _s.delete(key: _idKey(connectionId));
    await _s.delete(key: _secretKey(connectionId));
  });

  @override
  Future<void> deleteAll() => _guard(() async {
    final all = await _s.readAll();
    for (final k in all.keys.where((k) => k.startsWith(_prefix))) {
      await _s.delete(key: k);
    }
  });

  @override
  Future<bool> isAvailable() async {
    try {
      await _guard(() => _s.containsKey(key: '${_prefix}probe'));
      return true;
    } on SecureStorageUnavailableFailure {
      return false;
    }
  }
}
