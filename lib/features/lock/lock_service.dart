import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Salted, iterated SHA-256 PIN hashing. The PIN itself is never stored.
class PinHasher {
  const PinHasher({this.iterations = 20000});

  final int iterations;

  String newSalt([Random? random]) {
    final r = random ?? Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  String hash(String pin, String salt) {
    var digest = sha256.convert(utf8.encode('$salt:$pin')).bytes;
    for (var i = 0; i < iterations; i++) {
      digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
    }
    return base64Url.encode(digest);
  }

  bool verify(String pin, String salt, String expectedHash) {
    final actual = utf8.encode(hash(pin, salt));
    final expected = utf8.encode(expectedHash);
    if (actual.length != expected.length) return false;
    var diff = 0; // constant-time comparison
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }
}

/// Persistent store for the PIN hash and brute-force counters.
abstract class PinStore {
  Future<({String salt, String hash})?> read();
  Future<void> write(String salt, String hash);
  Future<void> clear();
  Future<int> failedAttempts();
  Future<void> setFailedAttempts(int n);
  Future<DateTime?> lockedUntil();
  Future<void> setLockedUntil(DateTime? t);
}

class SecurePinStore implements PinStore {
  SecurePinStore([FlutterSecureStorage? storage])
    : _s =
          storage ??
          const FlutterSecureStorage(
            // macOS: use the file-based keychain so unsigned/debug builds work without entitlements.
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
          );

  final FlutterSecureStorage _s;
  static const _salt = 'dashfolio.pin.salt';
  static const _hash = 'dashfolio.pin.hash';
  static const _fails = 'dashfolio.pin.fails';
  static const _until = 'dashfolio.pin.until';

  @override
  Future<({String salt, String hash})?> read() async {
    final salt = await _s.read(key: _salt);
    final hash = await _s.read(key: _hash);
    return salt == null || hash == null ? null : (salt: salt, hash: hash);
  }

  @override
  Future<void> write(String salt, String hash) async {
    await _s.write(key: _salt, value: salt);
    await _s.write(key: _hash, value: hash);
  }

  @override
  Future<void> clear() async {
    for (final k in [_salt, _hash, _fails, _until]) {
      await _s.delete(key: k);
    }
  }

  @override
  Future<int> failedAttempts() async => int.tryParse(await _s.read(key: _fails) ?? '') ?? 0;

  @override
  Future<void> setFailedAttempts(int n) => _s.write(key: _fails, value: '$n');

  @override
  Future<DateTime?> lockedUntil() async => DateTime.tryParse(await _s.read(key: _until) ?? '');

  @override
  Future<void> setLockedUntil(DateTime? t) => t == null ? _s.delete(key: _until) : _s.write(key: _until, value: t.toIso8601String());
}

/// Biometric prompt abstraction.
abstract class BiometricAuth {
  Future<bool> isAvailable();
  Future<bool> authenticate(String reason);
}

class LocalBiometricAuth implements BiometricAuth {
  LocalBiometricAuth([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } on Object {
      return false;
    }
  }
}

/// Cooldown after repeated wrong PINs: none for 4 failures, then 30s doubling up to 15 minutes.
Duration cooldownFor(int failedAttempts) {
  if (failedAttempts < 5) return Duration.zero;
  final steps = failedAttempts - 5;
  final seconds = 30 * pow(2, steps.clamp(0, 5)).toInt();
  return Duration(seconds: seconds.clamp(30, 900));
}
