import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/refresh_controller.dart';
import '../../core/failure.dart';
import '../../data/luno/luno_connect_service.dart';
import '../../data/luno/luno_credential_store.dart';
import '../../data/luno/luno_permission_probe.dart';
import '../../data/luno/luno_sync_service.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/luno.dart';
import '../../routing/routes.dart';
import '../common/page_scaffold.dart';
import 'luno_widgets.dart';
import 'step_up.dart';

/// Connect a Luno account: create a read-only key, check it, name the connection, run the first sync.
///
/// Requires the app lock (step-up authentication guards the key form) and a working secure store. The secret is held in
/// memory only between "Check key" and "Connect", then erased.
class LunoConnectScreen extends ConsumerStatefulWidget {
  const LunoConnectScreen({super.key});

  @override
  ConsumerState<LunoConnectScreen> createState() => _LunoConnectScreenState();
}

class _LunoConnectScreenState extends ConsumerState<LunoConnectScreen> {
  final _keyForm = GlobalKey<LunoKeyFormState>();
  final _label = TextEditingController(text: 'Luno');

  bool _storageChecked = false;
  bool _storageOk = true;
  bool _formUnlocked = false;
  bool _keyFilled = false;
  bool _checking = false;
  LunoKeyCheck? _check;
  LunoCredentials? _verified; // in memory only until connected
  String _verifiedHint = '';
  String _homeFiat = 'USD';
  bool _sendAbsent = false;
  bool _connecting = false;
  bool _cancelSync = false;
  LunoSyncProgress? _progress;
  LunoSyncResult? _result;
  int? _portfolioId;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(lunoCredentialStoreProvider).isAvailable().then((ok) {
      if (mounted) {
        setState(() {
          _storageChecked = true;
          _storageOk = ok;
        });
      }
    });
  }

  @override
  void dispose() {
    _verified = null;
    _label.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (await requireStepUp(context, ref, reason: 'Confirm it is you before entering an API key') && mounted) {
      setState(() => _formUnlocked = true);
    }
  }

  Future<void> _checkKey() async {
    final creds = _keyForm.currentState?.credentials;
    if (creds == null) return;
    setState(() {
      _checking = true;
      _error = null;
      _check = null;
      _verified = null;
    });
    try {
      final check = await ref.read(lunoConnectServiceProvider).verify(creds);
      if (!mounted) return;
      setState(() {
        _check = check;
        _verified = check.acceptable ? creds : null;
        _verifiedHint = creds.keyIdHint;
        if (check.acceptable) {
          _homeFiat = LunoConnectService.suggestHomeFiat(check.accounts, fallback: ref.read(appSettingsProvider).baseCurrency);
        }
      });
      // Whatever the outcome, only one copy of the secret should remain: `_verified` (or none, if the key was refused).
      _keyForm.currentState?.clear();
      setState(() => _keyFilled = false);
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = AppErrorRetry.messageFor(f));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _connect() async {
    final creds = _verified;
    final check = _check;
    if (creds == null || check == null || !check.acceptable || _connecting) return;
    if (!await requireStepUp(context, ref, reason: 'Confirm it is you to store the API key') || !mounted) return;
    setState(() {
      _connecting = true;
      _error = null;
      _cancelSync = false;
    });
    try {
      final id = await ref
          .read(lunoConnectServiceProvider)
          .connect(
            credentials: creds,
            check: check,
            label: _label.text,
            homeFiat: _homeFiat,
            costMethod: ref.read(appSettingsProvider).defaultCostMethod,
            sendPermissionConfirmedAbsent: _sendAbsent,
          );
      // The key now lives only in secure storage.
      _keyForm.currentState?.clear();
      _verified = null;
      _portfolioId = (await ref.read(lunoRepositoryProvider).getConnection(id))?.portfolioId;
      if (!mounted) return;
      setState(() => _progress = const LunoSyncProgress(phase: 'balances'));
      final result = await ref
          .read(lunoSyncServiceProvider)
          .sync(
            id,
            baseCurrency: ref.read(appSettingsProvider).baseCurrency,
            isCancelled: () => _cancelSync,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      ref.read(refreshControllerProvider.notifier).refresh(force: true);
      if (mounted) {
        setState(() {
          _result = result;
          _progress = null;
        });
      }
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = AppErrorRetry.messageFor(f));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final n = context.app;
    final done = _result != null;

    final children = <Widget>[
      if (!settings.lockEnabled)
        AppCard(
          child: LunoNotice(
            icon: AppIcon.lock,
            color: n.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Turn on the app lock first', style: context.text.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Your Luno API key is stored in your device\'s secure storage and every change to it asks for your PIN or biometrics. '
                  'That needs the app lock.',
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: AppSpace.s3),
                AppButton(label: 'Open Settings', icon: AppIcon.settings, onPressed: () => context.go(Routes.settings)),
              ],
            ),
          ),
        )
      else if (_storageChecked && !_storageOk)
        AppCard(
          child: LunoNotice(
            icon: AppIcon.shield,
            color: n.loss,
            child: Text(
              'Secure storage is not available on this device, so an API key cannot be kept safely. Dashfolio will not store it anywhere else. '
              'On Linux, install and unlock a Secret Service such as GNOME Keyring or KWallet.',
              style: context.text.bodyMedium,
            ),
          ),
        )
      else ...[
        _guide(context),
        _keyCard(context),
        if (_check != null) _checkCard(context, _check!),
        if (_verified != null && _check!.acceptable && !done) _detailsCard(context),
        if (_connecting || done) _syncCard(context),
      ],
      if (_error != null)
        LunoNotice(
          icon: AppIcon.error,
          color: n.loss,
          child: Semantics(liveRegion: true, child: Text(_error!)),
        ),
    ];

    return PageScaffold(
      title: 'Connect Luno',
      subtitle: 'Read-only access to your Luno account',
      showRefresh: false,
      leading: lunoBackButton(context, to: Routes.luno),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in children)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s4),
              child: c,
            ),
        ],
      ),
    );
  }

  Widget _guide(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('1. Create a read-only API key'),
        const SizedBox(height: AppSpace.s2),
        Text(
          'Dashfolio only ever reads your account. It cannot trade, send or withdraw, and it refuses keys that could.',
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: AppSpace.s3),
        for (final step in const [
          'Open the API keys page on Luno and choose "Add API key".',
          'Name it "Dashfolio" and choose a custom permission set (not a preset).',
          'Tick only: View balance, View transactions, View orders, View transfers and View withdrawals.',
          'Leave "Send to any address", "Create orders" and "Create or cancel withdrawals" unticked.',
          'Copy the key ID and the secret. Luno shows the secret only once.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(step, style: context.text.bodyMedium)),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.s2),
        Text(
          'Luno\'s "Read-only access" preset also includes "Send to any address", which Dashfolio cannot verify is switched off. A custom key is safer.',
          style: context.text.bodySmall!.copyWith(color: context.app.warning),
        ),
        const SizedBox(height: AppSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: 'Open Luno API keys',
            icon: AppIcon.openInNew,
            onPressed: () => launchUrl(kLunoApiKeysUrl, mode: LaunchMode.externalApplication),
          ),
        ),
      ],
    ),
  );

  Widget _keyCard(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('2. Enter your key'),
        const SizedBox(height: AppSpace.s2),
        if (!_formUnlocked) ...[
          Text('You will be asked for your PIN or biometrics before the form opens.', style: context.text.bodyMedium),
          const SizedBox(height: AppSpace.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(label: 'I have my key', icon: AppIcon.vpnKey, kind: AppButtonKind.primary, onPressed: _unlock),
          ),
        ] else ...[
          LunoKeyForm(
            key: _keyForm,
            enabled: !_checking && !_connecting && _result == null,
            onChanged: () => setState(() => _keyFilled = _keyForm.currentState?.isFilled ?? false),
          ),
          const SizedBox(height: AppSpace.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Check key',
              icon: AppIcon.verifiedUser,
              kind: AppButtonKind.primary,
              loading: _checking,
              onPressed: _keyFilled && !_connecting && _result == null ? _checkKey : null,
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          Text(
            'The secret is kept in secure storage on this device. It is never shown again, saved in backups or written to logs.',
            style: context.text.bodySmall,
          ),
        ],
      ],
    ),
  );

  Widget _checkCard(BuildContext context, LunoKeyCheck check) {
    final n = context.app;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('3. Key check'),
          const SizedBox(height: AppSpace.s2),
          LunoKeyCheckView(check),
          const SizedBox(height: AppSpace.s3),
          if (check.acceptable)
            LunoNotice(
              icon: AppIcon.verifiedUser,
              color: n.gain,
              child: Text(
                'Key ending …$_verifiedHint can read your account and cannot place orders or withdraw funds.',
                style: context.text.bodyMedium,
              ),
            )
          else
            LunoNotice(
              icon: AppIcon.block,
              color: n.loss,
              child: Text(lunoCheckProblem(check), style: context.text.bodyMedium),
            ),
          if (check.acceptable) ...[
            const SizedBox(height: AppSpace.s3),
            LunoNotice(
              icon: AppIcon.warningOutlined,
              color: n.warning,
              child: Text(
                'Dashfolio cannot test the "Send to any address" permission without moving money. Please confirm below that your key does not have it.',
                style: context.text.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailsCard(BuildContext context) {
    final currencies = lunoFiatCurrencies.toList()..sort();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('4. Name the connection'),
          const SizedBox(height: AppSpace.s3),
          AppTextField(controller: _label, label: 'Name', hint: 'Luno', enabled: !_connecting),
          const SizedBox(height: AppSpace.s4),
          Text('Your Luno currency', style: context.text.titleSmall),
          Text(
            'Your Luno crypto is tracked in this currency. Trades paid in another currency are converted at that day\'s rate.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpace.s2),
          SizedBox(
            width: 200,
            child: AppSelect<String>(
              value: currencies.contains(_homeFiat) ? _homeFiat : null,
              options: [for (final c in currencies) AppOption(c, c)],
              onChanged: _connecting ? null : (c) => setState(() => _homeFiat = c ?? _homeFiat),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          Row(
            children: [
              Expanded(child: Text('My key does not have "Send to any address"', style: context.text.bodyMedium)),
              AppSwitch(
                semanticLabel: 'My key does not have Send to any address',
                value: _sendAbsent,
                onChanged: _connecting ? null : (v) => setState(() => _sendAbsent = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Connect and sync',
              icon: AppIcon.link,
              kind: AppButtonKind.primary,
              loading: _connecting,
              onPressed: _connecting ? null : _connect,
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncCard(BuildContext context) {
    final n = context.app;
    final p = _progress;
    final r = _result;
    final phase = switch (p?.phase) {
      'balances' => 'Reading your balances…',
      'ledger' => 'Downloading history: ${p!.rowsFetched} entries (${p.accountsDone} of ${p.accountsTotal} wallets)…',
      'mapping' => 'Building your transactions…',
      'reconciling' => 'Checking balances…',
      _ => 'Starting…',
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(r == null ? '5. Syncing' : 'Connected'),
          const SizedBox(height: AppSpace.s3),
          if (r == null) ...[
            const AppProgress(height: 10),
            const SizedBox(height: AppSpace.s3),
            Semantics(liveRegion: true, child: Text(phase, style: context.text.bodyMedium)),
            const SizedBox(height: AppSpace.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(label: 'Stop (resume later)', onPressed: () => setState(() => _cancelSync = true)),
            ),
          ] else ...[
            LunoNotice(
              icon: r.ok ? AppIcon.checkCircle : AppIcon.error,
              color: r.ok ? n.gain : n.loss,
              child: Text(
                r.ok
                    ? 'Synced ${r.transactions} transactions from ${r.rowsFetched} ledger entries.'
                          '${r.mismatches.isEmpty ? '' : '\nSome balances do not match yet; see the connection for details.'}'
                    : 'The first sync did not finish: ${AppErrorRetry.messageFor(r.failure!)} You can resume it from the connection page.',
                style: context.text.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpace.s3),
            Wrap(
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s3,
              children: [
                if (_portfolioId != null)
                  AppButton(
                    label: 'Open portfolio',
                    icon: AppIcon.pieChart,
                    kind: AppButtonKind.primary,
                    onPressed: () => context.go(Routes.portfolio(_portfolioId!)),
                  ),
                AppButton(label: 'Done', onPressed: () => context.go(Routes.luno)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
