import 'package:dashfolio/app/app.dart';
import 'package:dashfolio/app/app_info.dart';
import 'package:dashfolio/app/file_service.dart';
import 'package:dashfolio/app/app_settings.dart' show AppSkin;
import 'package:dashfolio/app/portfolio_providers.dart';
import 'package:dashfolio/app/skin.dart';
import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/features/lock/lock_controller.dart';
import 'package:dashfolio/features/lock/lock_service.dart';
import 'package:dashfolio/domain/repositories/settings_repository.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fake_luno_credentials.dart';
import 'fake_market_data.dart';

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

class NoBiometrics implements BiometricAuth {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<bool> authenticate(String reason) async => false;
}

class FakeFileService implements FileService {
  PickedText? toPick;
  final saved = <String, String>{};

  @override
  Future<PickedText?> pickText(List<String> extensions) async => toPick;

  @override
  Future<bool> saveText({required String fileName, required String text, required String extension, required MimeType mime}) async {
    saved['$fileName.$extension'] = text;
    return true;
  }
}

/// Everything a widget test needs to drive the real app against in-memory fakes.
class AppHarness {
  AppHarness._(this.db, this.market, this.clock, this.files, this.pins, this.skin, this.cupertinoAvailable)
    : lunoCredentials = FakeLunoCredentialStore();

  final AppDatabase db;
  final FakeMarketData market;
  final FixedClock clock;
  final FakeFileService files;
  final MemoryPinStore pins;
  final FakeLunoCredentialStore lunoCredentials;

  /// The skin the app renders in. Neumorphic (the default) leaves the Cupertino skin unavailable, as on desktop-less CI.
  final AppSkin skin;

  /// Whether the Cupertino skin can be chosen. Follows [skin] unless a test says otherwise (for example the toggle).
  final bool cupertinoAvailable;

  late ProviderContainer container;

  /// Extra provider overrides a test wants on top of the standard fakes.
  final List<Override> extraOverrides = [];

  /// What Settings → About reports.
  AppInfo appInfo = const AppInfo(version: '1.0.0', buildNumber: '1');

  static AppHarness create({DateTime? now, AppSkin skin = AppSkin.neumorphic, bool? cupertinoAvailable}) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    return AppHarness._(
      AppDatabase(NativeDatabase.memory()),
      FakeMarketData(),
      FixedClock(now ?? DateTime.utc(2024, 6, 3, 15)),
      FakeFileService(),
      MemoryPinStore(),
      skin,
      cupertinoAvailable ?? skin == AppSkin.cupertino,
    );
  }

  List<Override> get overrides => [
    databaseProvider.overrideWithValue(db),
    marketDataRepositoryProvider.overrideWithValue(market),
    clockProvider.overrideWithValue(clock),
    fileServiceProvider.overrideWithValue(files),
    pinStoreProvider.overrideWithValue(pins),
    lunoCredentialStoreProvider.overrideWithValue(lunoCredentials),
    biometricAuthProvider.overrideWithValue(NoBiometrics()),
    cupertinoSkinAvailableProvider.overrideWithValue(cupertinoAvailable),
    // PackageInfo uses a platform channel.
    appInfoProvider.overrideWith((_) async => appInfo),
    // `compute` needs a real isolate, which never completes under fake async; run inline instead.
    historyRunnerProvider.overrideWithValue((args) async => runHistory(args)),
    ...extraOverrides,
    pinHasherProvider.overrideWithValue(const PinHasher(iterations: 10)),
  ];

  /// Marks onboarding as done so tests can start at the dashboard.
  Future<void> completeOnboarding({String baseCurrency = 'USD'}) async {
    final s = SettingsRepositoryLike(db);
    await s.set(SettingKeys.disclaimerAccepted, 'true');
    await s.set(SettingKeys.baseCurrency, baseCurrency);
    await s.set(SettingKeys.uiSkin, skin == AppSkin.cupertino ? 'cupertino' : 'neumorphic');
  }

  /// [size] null keeps the real view (on a device the app must stay attached to the actual screen).
  Future<void> pump(WidgetTester tester, {Size? size = const Size(1400, 1000)}) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container = ProviderContainer(overrides: overrides, retry: (_, _) => null),
        child: const DashfolioApp(),
      ),
    );
    await settle(tester);
  }

  /// Lets streams, routing and animations settle without relying on pumpAndSettle (live streams never idle).
  Future<void> settle(WidgetTester tester, {int frames = 12}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    // Drift keeps cancelled stream queries alive on a zero-length timer in the fake-async zone.
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }
}

/// Thin direct settings writer that avoids pulling in the Riverpod graph.
class SettingsRepositoryLike {
  SettingsRepositoryLike(this.db);
  final AppDatabase db;

  Future<void> set(String key, String value) =>
      db.into(db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
