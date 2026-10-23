import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/repositories/settings_repository.dart';
import '../luno/step_up.dart';
import 'lock_service.dart';

final pinStoreProvider = Provider<PinStore>((ref) => SecurePinStore());
final biometricAuthProvider = Provider<BiometricAuth>((ref) => LocalBiometricAuth());
final pinHasherProvider = Provider<PinHasher>((ref) => const PinHasher());

enum UnlockResult { success, wrongPin, coolingDown, noPin }

class LockState {
  const LockState({this.locked = false, this.ready = false, this.biometricAvailable = false, this.failedAttempts = 0, this.lockedUntil});

  /// Whether the app content is currently hidden behind the lock screen.
  final bool locked;

  /// False until persisted lock info has been read (avoids flashing content on cold start).
  final bool ready;
  final bool biometricAvailable;
  final int failedAttempts;
  final DateTime? lockedUntil;

  LockState copyWith({
    bool? locked,
    bool? ready,
    bool? biometricAvailable,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearUntil = false,
  }) => LockState(
    locked: locked ?? this.locked,
    ready: ready ?? this.ready,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: clearUntil ? null : (lockedUntil ?? this.lockedUntil),
  );
}

/// Owns the app-lock state machine: cold-start lock, timeout lock, PIN/biometric unlock.
class LockController extends Notifier<LockState> {
  DateTime? _backgroundedAt;
  bool _initialized = false;

  @override
  LockState build() {
    // Listen (rather than read) so the settings stream stays subscribed; the first value tells
    // us whether the lock is enabled.
    ref.listen(settingsMapProvider, (prev, next) {
      if (!_initialized && next.hasValue) {
        _initialized = true;
        _init(next.requireValue);
      }
    }, fireImmediately: true);
    // Start locked until we know otherwise so protected content never flashes.
    return const LockState(locked: true, ready: false);
  }

  Future<void> _init(Map<String, String> settings) async {
    final enabled = settings[SettingKeys.lockEnabled] == 'true';
    final store = ref.read(pinStoreProvider);
    final hasPin = await store.read() != null;
    final bio = await ref.read(biometricAuthProvider).isAvailable();
    final attempts = await store.failedAttempts();
    final until = await store.lockedUntil();
    state = LockState(locked: enabled && hasPin, ready: true, biometricAvailable: bio, failedAttempts: attempts, lockedUntil: until);
  }

  bool get enabled => ref.read(appSettingsProvider).lockEnabled;

  Duration? get cooldownRemaining {
    final until = state.lockedUntil;
    if (until == null) return null;
    final left = until.difference(ref.read(clockProvider).now());
    return left.isNegative ? null : left;
  }

  /// Called when the app leaves the foreground.
  void onBackgrounded() => _backgroundedAt = ref.read(clockProvider).now();

  /// Called when the app returns; locks if the configured timeout has elapsed.
  void onResumed() {
    if (!enabled || state.locked) return;
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null) return;
    final timeout = Duration(seconds: ref.read(appSettingsProvider).lockTimeoutSeconds);
    if (ref.read(clockProvider).now().difference(since) >= timeout) state = state.copyWith(locked: true);
  }

  void lockNow() {
    if (enabled) state = state.copyWith(locked: true);
  }

  Future<UnlockResult> unlockWithPin(String pin) async {
    final store = ref.read(pinStoreProvider);
    if (cooldownRemaining != null) return UnlockResult.coolingDown;
    final saved = await store.read();
    if (saved == null) return UnlockResult.noPin;
    if (ref.read(pinHasherProvider).verify(pin, saved.salt, saved.hash)) {
      await store.setFailedAttempts(0);
      await store.setLockedUntil(null);
      state = state.copyWith(locked: false, failedAttempts: 0, clearUntil: true);
      return UnlockResult.success;
    }
    final attempts = state.failedAttempts + 1;
    final cool = cooldownFor(attempts);
    final until = cool == Duration.zero ? null : ref.read(clockProvider).now().add(cool);
    await store.setFailedAttempts(attempts);
    await store.setLockedUntil(until);
    state = state.copyWith(failedAttempts: attempts, lockedUntil: until, clearUntil: until == null);
    return until == null ? UnlockResult.wrongPin : UnlockResult.coolingDown;
  }

  Future<bool> unlockWithBiometric() async {
    if (!ref.read(appSettingsProvider).lockBiometric || !state.biometricAvailable) return false;
    final ok = await ref.read(biometricAuthProvider).authenticate('Unlock Dashfolio');
    if (ok) state = state.copyWith(locked: false);
    return ok;
  }

  /// Turns the lock on with a new PIN (the user is already inside the app).
  Future<void> enable(String pin) async {
    final hasher = ref.read(pinHasherProvider);
    final salt = hasher.newSalt();
    await ref.read(pinStoreProvider).write(salt, hasher.hash(pin, salt));
    await ref.read(settingsRepositoryProvider).set(SettingKeys.lockEnabled, 'true');
    state = state.copyWith(locked: false, failedAttempts: 0, clearUntil: true);
  }

  /// Verifies [currentPin] before changing or disabling.
  Future<bool> verifyPin(String currentPin) async {
    final saved = await ref.read(pinStoreProvider).read();
    return saved != null && ref.read(pinHasherProvider).verify(currentPin, saved.salt, saved.hash);
  }

  /// Turns the lock off. Luno API keys are protected by the lock, so every connection is removed first (its key is
  /// deleted from secure storage and its portfolio kept). If a key cannot be deleted the lock stays on.
  Future<void> disable() async {
    await ref.read(lunoConnectServiceProvider).disconnectAll(keepPortfolios: true);
    await _turnOff();
  }

  Future<void> _turnOff() async {
    await ref.read(pinStoreProvider).clear();
    await ref.read(settingsRepositoryProvider).set(SettingKeys.lockEnabled, 'false');
    state = state.copyWith(locked: false, failedAttempts: 0, clearUntil: true);
  }

  /// "Forgot PIN": wipes all user data, then removes the lock.
  Future<void> resetApp() async {
    // Secrets first: they must not outlive the data they belong to, even if the PIN is lost.
    try {
      await ref.read(lunoCredentialStoreProvider).deleteAll();
    } on Object {
      // Best effort: the reset must still complete when the secure store is unavailable.
    }
    await ref.read(portfolioRepositoryProvider).wipeUserData();
    await _turnOff(); // not disable(): a reset must work even when the secure store does not
    ref.read(stepUpProvider.notifier).reset();
  }

  void refreshCooldown() {
    if (state.lockedUntil != null && cooldownRemaining == null) state = state.copyWith(clearUntil: true);
  }
}

final lockControllerProvider = NotifierProvider<LockController, LockState>(LockController.new);
