import 'package:flutter/material.dart';

import '../domain/entities/enums.dart';
import '../domain/repositories/settings_repository.dart';

/// Which UI kit renders the app. Chosen in Settings; see `SPEC_CUPERTINO.md`.
enum AppSkin { neumorphic, cupertino }

/// Typed view over the key/value settings table.
class AppSettings {
  const AppSettings({
    this.baseCurrency = 'USD',
    this.themeMode = ThemeMode.system,
    this.skin,
    this.defaultCostMethod = CostMethod.average,
    this.lockEnabled = false,
    this.lockTimeoutSeconds = 60,
    this.lockBiometric = true,
    this.proxyUrlOverride,
    this.lastRefreshAt,
    this.disclaimerAccepted = false,
    this.sidebarCollapsed = false,
    this.loaded = false,
  });

  final String baseCurrency;
  final ThemeMode themeMode;

  /// The stored skin, or null when the user never chose one (see `effectiveSkinProvider`).
  final AppSkin? skin;
  final CostMethod defaultCostMethod;
  final bool lockEnabled;
  final int lockTimeoutSeconds;
  final bool lockBiometric;
  final String? proxyUrlOverride;
  final DateTime? lastRefreshAt;
  final bool disclaimerAccepted;
  final bool sidebarCollapsed;

  /// False until the settings table has been read at least once.
  final bool loaded;

  factory AppSettings.fromMap(Map<String, String> m) => AppSettings(
    baseCurrency: m[SettingKeys.baseCurrency] ?? 'USD',
    themeMode: switch (m[SettingKeys.themeMode]) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    },
    skin: switch (m[SettingKeys.uiSkin]) {
      'neumorphic' => AppSkin.neumorphic,
      'cupertino' => AppSkin.cupertino,
      _ => null,
    },
    defaultCostMethod: CostMethod.parse(m[SettingKeys.defaultCostMethod]),
    lockEnabled: m[SettingKeys.lockEnabled] == 'true',
    lockTimeoutSeconds: int.tryParse(m[SettingKeys.lockTimeoutSeconds] ?? '') ?? 60,
    lockBiometric: m[SettingKeys.lockBiometric] != 'false',
    proxyUrlOverride: (m[SettingKeys.proxyUrlOverride]?.trim().isEmpty ?? true) ? null : m[SettingKeys.proxyUrlOverride]!.trim(),
    lastRefreshAt: DateTime.tryParse(m[SettingKeys.lastRefreshAt] ?? ''),
    disclaimerAccepted: m[SettingKeys.disclaimerAccepted] == 'true',
    sidebarCollapsed: m[SettingKeys.sidebarCollapsed] == 'true',
    loaded: true,
  );

  static String themeModeName(ThemeMode m) => switch (m) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static String skinName(AppSkin s) => switch (s) {
    AppSkin.neumorphic => 'neumorphic',
    AppSkin.cupertino => 'cupertino',
  };
}

/// Common ISO currencies offered for base-currency selection.
const kCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'JPY',
  'CHF',
  'CAD',
  'AUD',
  'NZD',
  'CNY',
  'HKD',
  'SGD',
  'SEK',
  'NOK',
  'DKK',
  'INR',
  'KRW',
  'BRL',
  'MXN',
  'ZAR',
  'TRY',
  'PLN',
  'ILS',
  'AED',
  'SAR',
  'THB',
  'IDR',
  'MYR',
];
