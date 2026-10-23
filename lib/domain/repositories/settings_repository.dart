abstract class SettingKeys {
  static const baseCurrency = 'base_currency';
  static const themeMode = 'theme_mode';
  static const defaultCostMethod = 'default_cost_method';
  static const lockEnabled = 'lock_enabled';
  static const lockTimeoutSeconds = 'lock_timeout_s';
  static const lockBiometric = 'lock_biometric';
  static const proxyUrlOverride = 'proxy_url_override';
  static const lastRefreshAt = 'last_refresh_at';
  static const disclaimerAccepted = 'disclaimer_accepted';
  static const sidebarCollapsed = 'sidebar_collapsed';
  static const uiSkin = 'ui_skin';
}

abstract class SettingsRepository {
  Stream<Map<String, String>> watchAll();
  Future<Map<String, String>> getAll();
  Future<String?> get(String key);
  Future<void> set(String key, String value);
  Future<void> remove(String key);
}
