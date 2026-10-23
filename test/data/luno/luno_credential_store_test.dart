import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockStorage storage;
  late SecureLunoCredentialStore store;
  final backing = <String, String>{};

  setUp(() {
    backing.clear();
    storage = _MockStorage();
    store = SecureLunoCredentialStore(storage);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((i) async {
      backing[i.namedArguments[#key] as String] = i.namedArguments[#value] as String;
    });
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((i) async => backing[i.namedArguments[#key]]);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((i) async {
      backing.remove(i.namedArguments[#key]);
    });
    when(() => storage.readAll()).thenAnswer((_) async => {...backing});
    when(() => storage.containsKey(key: any(named: 'key'))).thenAnswer((i) async => backing.containsKey(i.namedArguments[#key]));
  });

  test('stores the key id and secret under per-connection keys and reads them back', () async {
    await store.write(7, const LunoCredentials(keyId: 'id7', keySecret: 'secret7'));
    expect(backing.keys.toSet(), {'dashfolio.luno.7.keyId', 'dashfolio.luno.7.secret'});
    final c = await store.read(7);
    expect((c!.keyId, c.keySecret), ('id7', 'secret7'));
    expect(await store.read(8), isNull);
  });

  test('delete removes both entries; deleteAll removes only Luno entries (never the PIN)', () async {
    await store.write(1, const LunoCredentials(keyId: 'a', keySecret: 'b'));
    await store.write(2, const LunoCredentials(keyId: 'c', keySecret: 'd'));
    backing['dashfolio.pin.hash'] = 'pin-hash';
    await store.delete(1);
    expect(backing.keys.where((k) => k.startsWith('dashfolio.luno.1.')), isEmpty);
    await store.deleteAll();
    expect(backing.keys, ['dashfolio.pin.hash']);
  });

  test('platform errors become SecureStorageUnavailableFailure, never a silent fallback', () async {
    when(() => storage.read(key: any(named: 'key'))).thenThrow(PlatformException(code: 'libsecret_failed'));
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenThrow(PlatformException(code: 'locked'));
    await expectLater(store.read(1), throwsA(isA<SecureStorageUnavailableFailure>()));
    await expectLater(store.write(1, const LunoCredentials(keyId: 'a', keySecret: 'b')), throwsA(isA<SecureStorageUnavailableFailure>()));
    when(() => storage.containsKey(key: any(named: 'key'))).thenThrow(PlatformException(code: 'locked'));
    expect(await store.isAvailable(), isFalse);
    expect(backing, isEmpty);
  });

  test('available when the store responds', () async {
    expect(await store.isAvailable(), isTrue);
  });

  test('the default storage uses device-only, non-synchronizable keychain options on Apple platforms', () {
    final s = SecureLunoCredentialStore.defaultStorage;
    expect(s.iOptions.accessibility, KeychainAccessibility.unlocked_this_device);
    expect(s.iOptions.synchronizable, isFalse);
    expect(s.mOptions.accessibility, KeychainAccessibility.unlocked_this_device);
    expect(s.mOptions.synchronizable, isFalse);
    expect((s.mOptions as MacOsOptions).usesDataProtectionKeychain, isFalse);
  });
}
