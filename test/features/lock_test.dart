import 'dart:math';

import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/domain/repositories/settings_repository.dart';
import 'package:dashfolio/features/lock/lock_controller.dart';
import 'package:dashfolio/features/lock/lock_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_luno_credentials.dart';

class MemoryPinStore implements PinStore {
  ({String salt, String hash})? value;
  int fails = 0;
  DateTime? until;

  @override
  Future<({String salt, String hash})?> read() async => value;
  @override
  Future<void> write(String salt, String hash) async => value = (salt: salt, hash: hash);
  @override
  Future<void> clear() async {
    value = null;
    fails = 0;
    until = null;
  }

  @override
  Future<int> failedAttempts() async => fails;
  @override
  Future<void> setFailedAttempts(int n) async => fails = n;
  @override
  Future<DateTime?> lockedUntil() async => until;
  @override
  Future<void> setLockedUntil(DateTime? t) async => until = t;
}

class FakeBiometrics implements BiometricAuth {
  FakeBiometrics({this.available = true, this.succeeds = true});
  bool available;
  bool succeeds;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> authenticate(String reason) async => succeeds;
}

void main() {
  group('PinHasher', () {
    const hasher = PinHasher(iterations: 50);
    test('same pin+salt hashes identically; different salt/pin differs', () {
      expect(hasher.hash('1234', 's1'), hasher.hash('1234', 's1'));
      expect(hasher.hash('1234', 's1'), isNot(hasher.hash('1234', 's2')));
      expect(hasher.hash('1234', 's1'), isNot(hasher.hash('1235', 's1')));
    });
    test('verify accepts only the right pin and never exposes it', () {
      final salt = hasher.newSalt(Random(1));
      final h = hasher.hash('4821', salt);
      expect(h, isNot(contains('4821')));
      expect(hasher.verify('4821', salt, h), isTrue);
      expect(hasher.verify('4822', salt, h), isFalse);
    });
    test('salts are unique', () => expect(hasher.newSalt(), isNot(hasher.newSalt())));
  });

  test('cooldown escalates after five failures and caps at 15 minutes', () {
    expect(cooldownFor(0), Duration.zero);
    expect(cooldownFor(4), Duration.zero);
    expect(cooldownFor(5), const Duration(seconds: 30));
    expect(cooldownFor(6), const Duration(seconds: 60));
    expect(cooldownFor(7), const Duration(seconds: 120));
    expect(cooldownFor(50), const Duration(minutes: 15));
  });

  group('LockController', () {
    late AppDatabase db;
    late MemoryPinStore store;
    late FakeBiometrics bio;
    late FixedClock clock;
    late ProviderContainer container;
    late FakeLunoCredentialStore lunoStore;

    Future<LockController> make({bool enabled = false}) async {
      db = AppDatabase(NativeDatabase.memory());
      store = MemoryPinStore();
      lunoStore = FakeLunoCredentialStore();
      bio = FakeBiometrics();
      clock = FixedClock(DateTime.utc(2024, 6, 1, 12));
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          pinStoreProvider.overrideWithValue(store),
          lunoCredentialStoreProvider.overrideWithValue(lunoStore),
          biometricAuthProvider.overrideWithValue(bio),
          pinHasherProvider.overrideWithValue(const PinHasher(iterations: 10)),
          clockProvider.overrideWithValue(clock),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      if (enabled) {
        final h = const PinHasher(iterations: 10);
        store.value = (salt: 's', hash: h.hash('2468', 's'));
        await container.read(settingsRepositoryProvider).set(SettingKeys.lockEnabled, 'true');
      }
      // Riverpod 3 pauses providers nobody listens to; the app root watches this one, so do the same.
      container.listen(lockControllerProvider, (_, _) {});
      await container.read(settingsMapProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return container.read(lockControllerProvider.notifier);
    }

    LockState state() => container.read(lockControllerProvider);

    test('starts unlocked and ready when lock is disabled', () async {
      await make();
      expect(state().ready, isTrue);
      expect(state().locked, isFalse);
    });

    test('starts locked on cold start when enabled', () async {
      await make(enabled: true);
      expect(state().ready, isTrue);
      expect(state().locked, isTrue);
      expect(state().biometricAvailable, isTrue);
    });

    test('correct pin unlocks; wrong pin is counted', () async {
      final c = await make(enabled: true);
      expect(await c.unlockWithPin('0000'), UnlockResult.wrongPin);
      expect(state().failedAttempts, 1);
      expect(state().locked, isTrue);
      expect(await c.unlockWithPin('2468'), UnlockResult.success);
      expect(state().locked, isFalse);
      expect(state().failedAttempts, 0);
      expect(store.fails, 0);
    });

    test('five wrong pins trigger a cooldown that blocks even the right pin until it passes', () async {
      final c = await make(enabled: true);
      for (var i = 0; i < 4; i++) {
        expect(await c.unlockWithPin('1111'), UnlockResult.wrongPin);
      }
      expect(await c.unlockWithPin('1111'), UnlockResult.coolingDown);
      expect(c.cooldownRemaining, isNotNull);
      expect(await c.unlockWithPin('2468'), UnlockResult.coolingDown);
      expect(state().locked, isTrue);

      clock.value = clock.value.add(const Duration(seconds: 31));
      expect(c.cooldownRemaining, isNull);
      expect(await c.unlockWithPin('2468'), UnlockResult.success);
    });

    test('biometric unlock respects availability and the setting', () async {
      final c = await make(enabled: true);
      expect(await c.unlockWithBiometric(), isTrue);
      expect(state().locked, isFalse);

      final c2 = await make(enabled: true);
      bio.succeeds = false;
      expect(await c2.unlockWithBiometric(), isFalse);
      expect(state().locked, isTrue);
    });

    test('locks after the background timeout but not before', () async {
      final c = await make(enabled: true);
      await c.unlockWithPin('2468');
      await container.read(settingsRepositoryProvider).set(SettingKeys.lockTimeoutSeconds, '60');
      await container.read(settingsMapProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      c.onBackgrounded();
      clock.value = clock.value.add(const Duration(seconds: 30));
      c.onResumed();
      expect(state().locked, isFalse);

      c.onBackgrounded();
      clock.value = clock.value.add(const Duration(seconds: 61));
      c.onResumed();
      expect(state().locked, isTrue);
    });

    test('enable stores a hash, disable clears everything, resetApp wipes data', () async {
      final c = await make();
      await c.enable('9999');
      expect(store.value, isNotNull);
      expect(store.value!.hash, isNot(contains('9999')));
      expect(await c.verifyPin('9999'), isTrue);
      expect(await c.verifyPin('1111'), isFalse);
      expect(await container.read(settingsRepositoryProvider).get(SettingKeys.lockEnabled), 'true');

      await c.disable();
      expect(store.value, isNull);
      expect(await container.read(settingsRepositoryProvider).get(SettingKeys.lockEnabled), 'false');
    });

    group('with Luno connections', () {
      late int connectionId;

      Future<LockController> makeWithLuno() async {
        final c = await make(enabled: true);
        final pid = await container.read(portfolioRepositoryProvider).createPortfolio(const NewPortfolio(name: 'Luno – Main'));
        connectionId = await container
            .read(lunoRepositoryProvider)
            .createConnection(label: 'Main', portfolioId: pid, keyIdHint: 'abcd', homeFiat: 'MYR', status: LunoConnectionStatus.ok);
        await lunoStore.write(connectionId, const LunoCredentials(keyId: 'k', keySecret: 's'));
        return c;
      }

      test('turning the lock off deletes the keys and disconnects, keeping the portfolios', () async {
        final c = await makeWithLuno();
        await c.disable();
        expect(await lunoStore.read(connectionId), isNull);
        expect(await container.read(lunoRepositoryProvider).getConnections(), isEmpty);
        expect(await container.read(portfolioRepositoryProvider).getPortfolios(), hasLength(1));
        expect(await container.read(settingsRepositoryProvider).get(SettingKeys.lockEnabled), 'false');
      });

      test('if a key cannot be deleted the lock stays on and nothing changes', () async {
        final c = await makeWithLuno();
        lunoStore.available = false;
        await expectLater(c.disable(), throwsA(isA<SecureStorageUnavailableFailure>()));
        expect(await container.read(settingsRepositoryProvider).get(SettingKeys.lockEnabled), 'true');
        expect(store.value, isNotNull, reason: 'the PIN is still set');
        expect(await container.read(lunoRepositoryProvider).getConnections(), hasLength(1));
      });

      test('with no connections, an unavailable secure store (e.g. no keyring on Linux) does not stop the lock being turned off', () async {
        final c = await make(enabled: true);
        lunoStore.available = false;
        await c.disable();
        expect(await container.read(settingsRepositoryProvider).get(SettingKeys.lockEnabled), 'false');
      });

      test('resetApp wipes the keys and every Luno row, with or without a working secure store', () async {
        final c = await makeWithLuno();
        await c.resetApp();
        expect(await lunoStore.read(connectionId), isNull);
        expect(await container.read(lunoRepositoryProvider).getConnections(), isEmpty);
        expect(await container.read(portfolioRepositoryProvider).getPortfolios(), isEmpty);
        expect(state().locked, isFalse);

        final again = await makeWithLuno();
        lunoStore.available = false;
        await again.resetApp(); // still completes: the PIN may be lost, so the reset must not depend on the keychain
        expect(await container.read(portfolioRepositoryProvider).getPortfolios(), isEmpty);
      });
    });
  });
}
