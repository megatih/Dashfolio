import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/app_info.dart';
import '../../app/app_settings.dart';
import '../../app/file_service.dart';
import '../../app/portfolio_providers.dart';
import '../../app/providers.dart';
import '../../app/refresh_controller.dart';
import '../../app/skin.dart';
import '../../core/failure.dart';
import '../../data/backup/backup_service.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/luno.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../routing/routes.dart';
import '../common/page_scaffold.dart';
import '../lock/lock_controller.dart';
import '../lock/lock_screen.dart';
import '../luno/luno_widgets.dart';
import 'base_currency_rebaser.dart';

const kDisclaimer =
    'Market data comes from Yahoo Finance, may be delayed and may contain errors. Dashfolio is a tracking tool, not financial advice.';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final lock = ref.watch(lockControllerProvider);
    final appInfo = ref.watch(appInfoProvider).value;

    AppSection section(String title, List<Widget> children) => AppSection(title: title, children: children);

    return PageScaffold(
      title: 'Settings',
      showRefresh: false,
      width: AppPageWidth.readable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          section('Appearance', [
            AppFormRow(
              label: 'Theme',
              wide: true,
              control: AppSegmented<ThemeMode>(
                selected: s.themeMode,
                onChanged: (m) => settingsRepo.set(SettingKeys.themeMode, AppSettings.themeModeName(m)),
                segments: const [
                  AppSegment(ThemeMode.system, 'System', icon: AppIcon.brightnessAuto),
                  AppSegment(ThemeMode.light, 'Light', icon: AppIcon.lightMode),
                  AppSegment(ThemeMode.dark, 'Dark', icon: AppIcon.darkMode),
                ],
              ),
            ),
            if (ref.watch(cupertinoSkinAvailableProvider))
              AppFormRow(
                label: 'Interface style',
                description: 'Choose the look of the app. Applies immediately.',
                wide: true,
                control: AppSegmented<AppSkin>(
                  selected: ref.watch(effectiveSkinProvider),
                  onChanged: (v) => settingsRepo.set(SettingKeys.uiSkin, AppSettings.skinName(v)),
                  segments: const [AppSegment(AppSkin.neumorphic, 'Neumorphic'), AppSegment(AppSkin.cupertino, 'Cupertino')],
                ),
              ),
          ]),
          section('Portfolio', [
            AppFormRow(
              label: 'Base currency',
              description: 'All totals are shown in this currency.',
              control: AppSelect<String>(
                width: 160,
                value: kCurrencies.contains(s.baseCurrency) ? s.baseCurrency : null,
                options: [for (final c in kCurrencies) AppOption(c, c)],
                onChanged: (c) => c == null || c == s.baseCurrency ? null : _changeBase(context, ref, s.baseCurrency, c),
              ),
            ),
            AppFormRow(
              label: 'Default cost basis',
              description: 'Used for new portfolios.',
              control: AppSelect<CostMethod>(
                width: 200,
                value: s.defaultCostMethod,
                options: [for (final m in CostMethod.values) AppOption(m, m.label)],
                onChanged: (m) => m == null ? null : settingsRepo.set(SettingKeys.defaultCostMethod, m.name),
              ),
            ),
          ]),
          section('Security', [
            AppFormRow(
              label: 'App lock',
              description: kIsWeb
                  ? 'Hides the screen behind a PIN. On the web your data still lives in this browser.'
                  : 'Require a PIN${lock.biometricAvailable ? ' or biometrics' : ''} to open Dashfolio.',
              control: AppSwitch(semanticLabel: 'App lock', value: s.lockEnabled, onChanged: (v) => _toggleLock(context, ref, v)),
            ),
            if (s.lockEnabled) ...[
              if (lock.biometricAvailable)
                AppFormRow(
                  label: 'Unlock with biometrics',
                  control: AppSwitch(
                    semanticLabel: 'Unlock with biometrics',
                    value: s.lockBiometric,
                    onChanged: (v) => settingsRepo.set(SettingKeys.lockBiometric, '$v'),
                  ),
                ),
              AppFormRow(
                label: 'Lock after',
                description: 'Time in the background before the PIN is required.',
                control: AppSelect<int>(
                  width: 180,
                  value: const [0, 30, 60, 300, 900].contains(s.lockTimeoutSeconds) ? s.lockTimeoutSeconds : 60,
                  options: const [
                    AppOption(0, 'Immediately'),
                    AppOption(30, '30 seconds'),
                    AppOption(60, '1 minute'),
                    AppOption(300, '5 minutes'),
                    AppOption(900, '15 minutes'),
                  ],
                  onChanged: (v) => v == null ? null : settingsRepo.set(SettingKeys.lockTimeoutSeconds, '$v'),
                ),
              ),
              AppButtonGroup(
                buttons: [
                  AppButton(label: 'Change PIN', icon: AppIcon.password, onPressed: () => _changePin(context, ref)),
                  AppButton(label: 'Lock now', icon: AppIcon.lock, onPressed: () => ref.read(lockControllerProvider.notifier).lockNow()),
                ],
              ),
            ],
          ]),
          if (ref.watch(lunoSupportedProvider)) _lunoSection(context, ref, section),
          section('Your data', [
            Text('Everything is stored on this device. Back it up regularly.', style: context.text.bodyMedium),
            const AppGap(AppSpace.s4),
            AppButtonGroup(
              buttons: [
                AppButton(
                  label: 'Import CSV',
                  icon: AppIcon.uploadFile,
                  kind: AppButtonKind.primary,
                  onPressed: () => context.push(Routes.importCsv),
                ),
                AppButton(label: 'Export backup (JSON)', icon: AppIcon.download, onPressed: () => _exportBackup(context, ref)),
                AppButton(label: 'Export transactions (CSV)', icon: AppIcon.tableChart, onPressed: () => _exportCsv(context, ref)),
                AppButton(label: 'Restore backup', icon: AppIcon.restore, onPressed: () => _restore(context, ref)),
              ],
            ),
          ]),
          section('Data connection', [
            AppFormRow(
              label: 'Clear price cache',
              description: 'Removes cached quotes and history. Your portfolios are not affected.',
              control: AppButton(
                label: 'Clear cache',
                compact: true,
                onPressed: () async {
                  await ref.read(marketDataRepositoryProvider).clearCache();
                  await settingsRepo.remove(SettingKeys.lastRefreshAt);
                  if (context.mounted) showAppToast(context, 'Price cache cleared. Refresh to download prices again.');
                },
              ),
            ),
            _ProxyField(initial: s.proxyUrlOverride ?? ''),
            if (kIsWeb && !ref.watch(yahooConfigProvider).viaProxy)
              AppSectionItem(
                top: AppSpace.s3,
                child: Text(
                  'Browsers cannot call Yahoo Finance directly. Deploy the proxy in the project\'s proxy/ folder and enter its URL above.',
                  style: context.text.bodySmall!.copyWith(color: context.app.warning),
                ),
              ),
          ]),
          section('About', [
            Text('Dashfolio', style: context.text.titleSmall),
            if (appInfo != null) ...[
              const AppGap(AppSpace.s1),
              Text('Version ${appInfo.version}', style: context.text.bodySmall),
              if (appInfo.buildNumber.isNotEmpty) Text('Build ${appInfo.buildNumber}', style: context.text.bodySmall),
              Text(
                appInfo.buildDate == null
                    ? 'Build date: development build'
                    : 'Build date: ${DateFormat.yMMMd().format(appInfo.buildDate!.toLocal())}',
                style: context.text.bodySmall,
              ),
            ],
            const AppGap(AppSpace.s2),
            Text(kDisclaimer, style: context.text.bodyMedium),
            const AppGap(AppSpace.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: AppTextButton(
                label: 'Open-source licenses',
                onPressed: () => showAppLicenses(context, applicationName: 'Dashfolio', applicationVersion: appInfo?.label),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  /// Luno cannot be used from a browser (no CORS, and a key must not live in browser storage), so this is native-only.
  Widget _lunoSection(BuildContext context, WidgetRef ref, AppSection Function(String, List<Widget>) section) {
    final connections = ref.watch(lunoConnectionsProvider).value ?? const <LunoConnection>[];
    return section('Luno', [
      Text(
        connections.isEmpty
            ? 'Connect a read-only Luno API key to see your crypto balances, trades and history next to the rest of your portfolio.'
            : '${connections.length} connection${connections.length == 1 ? '' : 's'}. API keys are kept in secure storage on this device and never leave it except to talk to Luno.',
        style: context.text.bodyMedium,
      ),
      for (final c in connections)
        AppSectionItem(
          top: AppSpace.s3,
          child: Wrap(
            spacing: AppSpace.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(c.label, style: context.text.titleSmall),
              LunoStatusChip(c.status),
              Text(lunoSyncedText(c), style: context.text.bodySmall),
            ],
          ),
        ),
      const AppGap(AppSpace.s4),
      AppButtonGroup(
        buttons: [
          AppButton(
            label: connections.isEmpty ? 'Connect Luno' : 'Connect another',
            icon: AppIcon.addLink,
            kind: AppButtonKind.primary,
            onPressed: () => context.push(Routes.lunoConnect),
          ),
          if (connections.isNotEmpty)
            AppButton(label: 'Manage connections', icon: AppIcon.settingsEthernet, onPressed: () => context.push(Routes.luno)),
        ],
      ),
    ]);
  }

  Future<void> _changeBase(BuildContext context, WidgetRef ref, String oldBase, String newBase) async {
    final hasTx = (ref.read(transactionsProvider).value ?? const []).isNotEmpty;
    final ok = await showAppConfirm(
      context,
      title: 'Change base currency to $newBase?',
      message: hasTx
          ? 'Totals will be shown in $newBase. Exchange rates stored on your transactions are recalculated using Yahoo\'s historical rates where available.'
          : 'Totals will be shown in $newBase.',
      confirmLabel: 'Change to $newBase',
    );
    if (!ok || !context.mounted) return;
    final repo = ref.read(settingsRepositoryProvider);
    if (!hasTx) {
      await repo.set(SettingKeys.baseCurrency, newBase);
      return;
    }
    final result = await BaseCurrencyRebaser(
      portfolios: ref.read(portfolioRepositoryProvider),
      market: ref.read(marketDataRepositoryProvider),
    ).rebase(oldBase: oldBase, newBase: newBase, currentFx: ref.read(fxRatesProvider));
    await repo.set(SettingKeys.baseCurrency, newBase);
    if (context.mounted) showAppToast(context, describeRebase(result));
    ref.read(refreshControllerProvider.notifier).refresh(force: true);
  }

  Future<void> _toggleLock(BuildContext context, WidgetRef ref, bool on) async {
    final lock = ref.read(lockControllerProvider.notifier);
    if (on) {
      final pin = await askNewPin(context);
      if (pin != null) {
        await lock.enable(pin);
        if (context.mounted) showAppToast(context, 'App lock enabled');
      }
    } else if (await verifyCurrentPin(context, ref, title: 'Enter your PIN to turn off the lock')) {
      if (!context.mounted) return;
      final connections = await ref.read(lunoRepositoryProvider).getConnections();
      if (connections.isNotEmpty && context.mounted) {
        final ok = await showAppConfirm(
          context,
          title: 'Turn off the app lock?',
          message:
              'Your Luno API key is protected by the app lock. Turning it off disconnects ${connections.length == 1 ? 'your Luno account' : 'your ${connections.length} Luno accounts'}: the key is deleted from this device. '
              'The synced portfolios are kept as ordinary portfolios.',
          confirmLabel: 'Disconnect and turn off',
          destructive: true,
        );
        if (!ok || !context.mounted) return;
      }
      try {
        await lock.disable();
        if (context.mounted) showAppToast(context, 'App lock disabled');
      } on AppFailure catch (f) {
        if (context.mounted) showAppToast(context, '${AppErrorRetry.messageFor(f)} The app lock stays on.', error: true);
      }
    }
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    if (!await verifyCurrentPin(context, ref)) return;
    if (!context.mounted) return;
    final pin = await askNewPin(context, title: 'Choose a new PIN');
    if (pin == null) return;
    await ref.read(lockControllerProvider.notifier).enable(pin);
    if (context.mounted) showAppToast(context, 'PIN changed');
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final text = await ref.read(backupServiceProvider).exportJson();
    final stamp = ref.read(clockProvider).now().toIso8601String().substring(0, 10);
    final ok = await ref
        .read(fileServiceProvider)
        .saveText(fileName: 'dashfolio-backup-$stamp', text: text, extension: 'json', mime: MimeType.json);
    if (context.mounted) showAppToast(context, ok ? 'Backup saved' : 'Backup was not saved', error: !ok);
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final text = await ref.read(backupServiceProvider).exportTransactionsCsv();
    final stamp = ref.read(clockProvider).now().toIso8601String().substring(0, 10);
    final ok = await ref
        .read(fileServiceProvider)
        .saveText(fileName: 'dashfolio-transactions-$stamp', text: text, extension: 'csv', mime: MimeType.csv);
    if (context.mounted) showAppToast(context, ok ? 'Transactions exported' : 'Export was not saved', error: !ok);
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final picked = await ref.read(fileServiceProvider).pickText(const ['json']);
    if (picked == null || !context.mounted) return;
    final backup = ref.read(backupServiceProvider);
    final Map<String, Object?> json;
    try {
      json = backup.parse(picked.text);
    } on BackupFormatException catch (e) {
      showAppToast(context, e.message, error: true);
      return;
    }
    final p = backup.preview(json);
    final mode = await showAppModal<RestoreMode>(
      context,
      builder: (ctx) => AppDialog(
        title: 'Restore backup',
        actions: [
          AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          AppButton(label: 'Merge', onPressed: () => Navigator.pop(ctx, RestoreMode.merge)),
          AppButton(label: 'Replace everything', kind: AppButtonKind.danger, onPressed: () => Navigator.pop(ctx, RestoreMode.replace)),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${p.portfolios} portfolios · ${p.transactions} transactions · ${p.watchlists} watchlists${p.exportedAt == null ? '' : '\nExported ${p.exportedAt!.toLocal().toString().substring(0, 16)}'}',
              style: ctx.text.bodyMedium,
            ),
            const SizedBox(height: AppSpace.s3),
            Text('Merge adds what is missing and skips duplicates. Replace erases your current data first.', style: ctx.text.bodySmall),
          ],
        ),
      ),
    );
    if (mode == null || !context.mounted) return;
    if (mode == RestoreMode.replace) {
      final ok = await showAppConfirm(
        context,
        title: 'Replace all data?',
        message: 'Your current portfolios, transactions and watchlists will be erased and replaced by the backup.',
        confirmLabel: 'Replace',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
    }
    final summary = await backup.restore(json, mode);
    if (!context.mounted) return;
    showAppToast(
      context,
      'Restored ${summary.transactions} transactions in ${summary.portfolios} new portfolios${summary.skipped > 0 ? ' (${summary.skipped} skipped)' : ''}',
    );
    ref.read(refreshControllerProvider.notifier).refresh(force: true);
  }
}

class _ProxyField extends ConsumerStatefulWidget {
  const _ProxyField({required this.initial});
  final String initial;

  @override
  ConsumerState<_ProxyField> createState() => _ProxyFieldState();
}

class _ProxyFieldState extends ConsumerState<_ProxyField> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = _controller.text.trim();
    final uri = Uri.tryParse(v);
    if (v.isNotEmpty && (uri == null || !uri.hasScheme || !(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty)) {
      setState(() => _error = 'Enter a full URL such as https://dashfolio-proxy.example.workers.dev');
      return;
    }
    setState(() => _error = null);
    final repo = ref.read(settingsRepositoryProvider);
    if (v.isEmpty) {
      await repo.remove(SettingKeys.proxyUrlOverride);
    } else {
      await repo.set(SettingKeys.proxyUrlOverride, v);
    }
    if (mounted) showAppToast(context, v.isEmpty ? 'Proxy override cleared' : 'Proxy saved');
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Yahoo proxy URL', style: context.text.titleSmall),
      Text(
        kIsWeb ? 'Required on the web build (CORS).' : 'Optional: route requests through your own proxy instead of calling Yahoo directly.',
        style: context.text.bodySmall,
      ),
      const AppGap(AppSpace.s3),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              controller: _controller,
              hint: 'https://…',
              keyboardType: TextInputType.url,
              errorText: _error,
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(width: AppSpace.s3),
          AppButton(label: 'Save', onPressed: _save),
        ],
      ),
    ],
  );
}
