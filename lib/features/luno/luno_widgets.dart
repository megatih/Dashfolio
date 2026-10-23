import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/luno/luno_credential_store.dart';
import '../../data/luno/luno_permission_probe.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/luno.dart';
import '../../routing/routes.dart';

/// Where Luno creates API keys.
final Uri kLunoApiKeysUrl = Uri.parse('https://www.luno.com/wallet/settings/api_keys');

/// The permissions a key needs: just enough to read the account.
const kLunoRequiredPermissions = ['View balance', 'View transactions', 'View orders', 'View transfers', 'View withdrawals'];

/// Status with an icon and a label (never colour alone).
class LunoStatusChip extends StatelessWidget {
  const LunoStatusChip(this.status, {super.key});

  final LunoConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final (AppIcon icon, Color color) = switch (status) {
      LunoConnectionStatus.ok => (AppIcon.checkCircle, n.gain),
      LunoConnectionStatus.syncing => (AppIcon.sync, n.accent),
      LunoConnectionStatus.error => (AppIcon.error, n.loss),
      LunoConnectionStatus.revoked => (AppIcon.keyOff, n.loss),
      LunoConnectionStatus.credentialsMissing => (AppIcon.vpnKey, n.warning),
      LunoConnectionStatus.needsReview => (AppIcon.rule, n.warning),
    };
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconView(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(status.label, style: context.text.labelMedium!.copyWith(color: color)),
        ],
      ),
    );
  }
}

String lunoSyncedText(LunoConnection c) {
  final at = c.lastSyncAt?.toLocal();
  return at == null ? 'Never synced' : 'Synced ${Fmt.shortDate(at)}, ${Fmt.time(at)}';
}

/// A callout: icon, colour and text.
class LunoNotice extends StatelessWidget {
  const LunoNotice({super.key, required this.icon, required this.color, required this.child});

  final AppIcon icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppSurface(
    shape: AppShape.inset,
    depth: 1,
    padding: const EdgeInsets.all(AppSpace.s4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconView(icon, color: color),
        const SizedBox(width: AppSpace.s3),
        Expanded(child: child),
      ],
    ),
  );
}

Widget lunoBackButton(BuildContext context, {String to = Routes.settings}) => Padding(
  padding: const EdgeInsets.only(right: AppSpace.s3),
  child: AppIconButton(icon: AppIcon.arrowBack, tooltip: 'Back', onPressed: () => context.canPop() ? context.pop() : context.go(to)),
);

/// Key id and secret entry. The secret is write-only: it is never shown again, never autofilled or remembered by the
/// keyboard, and both controllers are wiped as soon as the credentials have been read.
class LunoKeyForm extends StatefulWidget {
  const LunoKeyForm({super.key, this.onChanged, this.enabled = true});

  final VoidCallback? onChanged;
  final bool enabled;

  @override
  State<LunoKeyForm> createState() => LunoKeyFormState();
}

class LunoKeyFormState extends State<LunoKeyForm> {
  final _id = TextEditingController();
  final _secret = TextEditingController();

  bool get isFilled => _id.text.trim().isNotEmpty && _secret.text.trim().isNotEmpty;

  /// Null until both fields are filled.
  LunoCredentials? get credentials => isFilled ? LunoCredentials(keyId: _id.text.trim(), keySecret: _secret.text.trim()) : null;

  /// Erases what was typed (called once the credentials have been verified or stored).
  void clear() {
    _id.clear();
    _secret.clear();
  }

  @override
  void dispose() {
    clear();
    _id.dispose();
    _secret.dispose();
    super.dispose();
  }

  // Key ids and secrets are plain URL-safe tokens.
  static final _tokenChars = [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-+/=.]'))];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppTextField(
        controller: _id,
        label: 'API key ID',
        hint: 'e.g. cnz2yjswbv3jd',
        sensitive: true,
        enabled: widget.enabled,
        inputFormatters: _tokenChars,
        onChanged: (_) => widget.onChanged?.call(),
      ),
      const SizedBox(height: AppSpace.s4),
      AppTextField(
        controller: _secret,
        label: 'API key secret',
        hint: 'Paste the secret shown once by Luno',
        sensitive: true,
        enabled: widget.enabled,
        inputFormatters: _tokenChars,
        onChanged: (_) => widget.onChanged?.call(),
      ),
    ],
  );
}

/// The result of checking a key, as a checklist.
class LunoKeyCheckView extends StatelessWidget {
  const LunoKeyCheckView(this.check, {super.key});

  final LunoKeyCheck check;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    Widget row(AppIcon icon, Color color, String text, {String? detail}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconView(icon, size: 18, color: color),
          const SizedBox(width: AppSpace.s2),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: text,
                children: [if (detail != null) TextSpan(text: ' $detail', style: context.text.bodySmall)],
              ),
            ),
          ),
        ],
      ),
    );
    Widget need(String label, bool ok) =>
        row(ok ? AppIcon.checkCircle : AppIcon.cancel, ok ? n.gain : n.loss, label, detail: ok ? null : '(missing)');
    Widget optional(String label, bool ok) =>
        row(ok ? AppIcon.checkCircle : AppIcon.info, ok ? n.gain : n.warning, label, detail: ok ? '(optional)' : '(optional, not granted)');
    Widget write(String label, LunoPermissionState s) => switch (s) {
      LunoPermissionState.absent => row(AppIcon.checkCircle, n.gain, '$label: not allowed'),
      LunoPermissionState.present => row(AppIcon.danger, n.loss, '$label: ALLOWED', detail: '(this key can change your account)'),
      LunoPermissionState.unknown => row(AppIcon.helpOutline, n.warning, '$label: could not be checked'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        need('View balance', check.readBalance),
        need('View transactions', check.readTransactions),
        need('View orders', check.readOrders),
        optional('View transfers', check.readTransfers),
        optional('View withdrawals', check.readWithdrawals),
        const SizedBox(height: AppSpace.s2),
        write('Create or stop orders', check.writeOrders),
        write('Request or cancel withdrawals', check.writeWithdrawals),
      ],
    );
  }
}

/// Why a key was refused, in words.
String lunoCheckProblem(LunoKeyCheck c) {
  if (c.hasDangerousWrites) {
    return 'This key can place orders or withdraw funds. Dashfolio only needs to read your account. '
        'Create a new key with just the view permissions listed above.';
  }
  if (!c.hasRequiredReads) {
    return 'This key is missing permissions Dashfolio needs to read your account. '
        'Create a key with the view permissions listed above.';
  }
  if (c.inconclusive) {
    return 'Luno answered in a way Dashfolio could not interpret, so the key cannot be confirmed as read-only. '
        'Try again, or create a new key.';
  }
  return '';
}

/// "Luno · synced hh:mm" marker for portfolios that mirror a Luno account, with the status when it needs attention.
class LunoPortfolioBadge extends StatelessWidget {
  const LunoPortfolioBadge(this.connection, {super.key});

  final LunoConnection connection;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final ok = connection.status == LunoConnectionStatus.ok;
    return Wrap(
      spacing: AppSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppIconView(AppIcon.lock, size: 12, color: n.textMuted),
        Text('Luno · ${lunoSyncedText(connection).toLowerCase()}', style: context.text.labelSmall!.copyWith(color: n.textMuted)),
        if (!ok) LunoStatusChip(connection.status),
      ],
    );
  }
}
