import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/refresh_controller.dart';
import '../../core/failure.dart';
import '../../core/format.dart';
import '../../data/luno/luno_permission_probe.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/luno.dart';
import '../../routing/routes.dart';
import 'luno_widgets.dart';
import 'step_up.dart';

/// Syncs one connection now and refreshes prices for what it brought in.
Future<void> runLunoSync(BuildContext context, WidgetRef ref, LunoConnection c) async {
  final result = await ref.read(lunoSyncServiceProvider).sync(c.id, baseCurrency: ref.read(appSettingsProvider).baseCurrency);
  if (result.skipped && context.mounted) {
    showAppToast(context, 'This connection cannot sync right now: ${c.status.label.toLowerCase()}.', error: true);
    return;
  }
  ref.read(refreshControllerProvider.notifier).refresh(force: true);
  if (!context.mounted) return;
  if (result.failure != null) {
    showAppToast(context, AppErrorRetry.messageFor(result.failure!), error: true);
  } else if (result.mismatches.isNotEmpty) {
    showAppToast(context, 'Synced, but some balances differ from Luno. Open the connection to review.', error: true);
  } else {
    showAppToast(context, result.rowsFetched == 0 ? 'Already up to date' : 'Synced ${result.rowsFetched} new ledger entries');
  }
}

Future<void> renameConnection(BuildContext context, WidgetRef ref, LunoConnection c) async {
  final name = await showAppModal<String>(context, builder: (_) => _RenameDialog(initial: c.label));
  if (name == null || name.isEmpty || name == c.label) return;
  await ref.read(lunoRepositoryProvider).updateConnection(c.copyWith(label: name));
}

/// Owns its text controller so it is disposed only after the dialog's closing animation has finished.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppDialog(
    title: 'Rename connection',
    actions: [
      AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
      AppButton(label: 'Save', kind: AppButtonKind.primary, onPressed: () => Navigator.pop(context, _controller.text.trim())),
    ],
    child: AppTextField(controller: _controller, label: 'Name', autofocus: true, onSubmitted: (v) => Navigator.pop(context, v.trim())),
  );
}

Future<void> changeHomeFiat(BuildContext context, WidgetRef ref, LunoConnection c) async {
  final currencies = lunoFiatCurrencies.toList()..sort();
  var selected = c.homeFiat;
  final chosen = await showAppModal<String>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AppDialog(
        title: 'Your Luno currency',
        actions: [
          AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          AppButton(label: 'Change', kind: AppButtonKind.primary, onPressed: () => Navigator.pop(ctx, selected)),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Luno crypto is tracked in this currency. Trades paid in another currency are converted at that day\'s rate. '
              'Your transactions are rebuilt from the history already downloaded.',
              style: ctx.text.bodyMedium,
            ),
            const SizedBox(height: AppSpace.s3),
            SizedBox(
              width: 200,
              child: AppSelect<String>(
                value: selected,
                options: [for (final x in currencies) AppOption(x, x)],
                onChanged: (v) => setState(() => selected = v ?? selected),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (chosen == null || chosen == c.homeFiat) return;
  await ref.read(lunoRepositoryProvider).updateConnection(c.copyWith(homeFiat: chosen));
  await ref.read(lunoSyncServiceProvider).remapAll(c.id, baseCurrency: ref.read(appSettingsProvider).baseCurrency);
  ref.read(refreshControllerProvider.notifier).refresh(force: true);
  if (context.mounted) showAppToast(context, 'Now valuing in $chosen');
}

/// Re-reads every stored ledger entry with the current rules. Nothing is downloaded.
Future<void> rebuildFromHistory(BuildContext context, WidgetRef ref, LunoConnection c) async {
  await ref.read(lunoSyncServiceProvider).remapAll(c.id, baseCurrency: ref.read(appSettingsProvider).baseCurrency);
  if (context.mounted) await runLunoSync(context, ref, c);
}

Future<void> replaceKey(BuildContext context, WidgetRef ref, LunoConnection c) async {
  if (!await requireStepUp(context, ref, reason: 'Confirm it is you to replace the API key') || !context.mounted) return;
  final formKey = GlobalKey<LunoKeyFormState>();
  LunoKeyCheck? refused;
  String? error;
  var busy = false;
  var filled = false;
  final replaced = await showAppModal<bool>(
    context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AppDialog(
        title: 'Replace API key',
        actions: [
          AppTextButton(label: 'Cancel', onPressed: busy ? null : () => Navigator.pop(ctx, false)),
          AppButton(
            label: 'Verify and replace',
            kind: AppButtonKind.primary,
            loading: busy,
            onPressed: !filled || busy
                ? null
                : () async {
                    final creds = formKey.currentState?.credentials;
                    if (creds == null) return;
                    setState(() {
                      busy = true;
                      error = null;
                      refused = null;
                    });
                    final service = ref.read(lunoConnectServiceProvider);
                    try {
                      final check = await service.verify(creds);
                      if (check.acceptable) await service.replaceKey(connectionId: c.id, credentials: creds, check: check);
                      formKey.currentState?.clear();
                      if (!ctx.mounted) return;
                      if (check.acceptable) {
                        Navigator.pop(ctx, true);
                      } else {
                        setState(() {
                          refused = check;
                          filled = false;
                        });
                      }
                    } on AppFailure catch (f) {
                      formKey.currentState?.clear();
                      if (ctx.mounted) {
                        setState(() {
                          error = AppErrorRetry.messageFor(f);
                          filled = false;
                        });
                      }
                    } finally {
                      if (ctx.mounted) setState(() => busy = false);
                    }
                  },
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Use a new read-only key for the same Luno account. '
              'The old key is overwritten on this device (revoke it in Luno if it is no longer needed).',
              style: ctx.text.bodyMedium,
            ),
            const SizedBox(height: AppSpace.s3),
            LunoKeyForm(key: formKey, enabled: !busy, onChanged: () => setState(() => filled = formKey.currentState?.isFilled ?? false)),
            if (error != null) ...[
              const SizedBox(height: AppSpace.s3),
              Text(error!, style: ctx.text.bodySmall!.copyWith(color: ctx.app.loss)),
            ],
            if (refused != null) ...[
              const SizedBox(height: AppSpace.s3),
              LunoKeyCheckView(refused!),
              const SizedBox(height: AppSpace.s2),
              Text(lunoCheckProblem(refused!), style: ctx.text.bodySmall!.copyWith(color: ctx.app.loss)),
            ],
          ],
        ),
      ),
    ),
  );
  if (replaced == true && context.mounted) {
    showAppToast(context, 'API key replaced');
    await runLunoSync(context, ref, c.copyWith(status: LunoConnectionStatus.ok));
  }
}

/// Wipes the key and either keeps the data as an ordinary portfolio or deletes it.
Future<void> disconnectConnection(BuildContext context, WidgetRef ref, LunoConnection c) async {
  if (!await requireStepUp(context, ref, reason: 'Confirm it is you to disconnect Luno') || !context.mounted) return;
  final choice = await showAppModal<bool>(
    context,
    builder: (ctx) => AppDialog(
      title: 'Disconnect "${c.label}"?',
      actions: [
        AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
        AppButton(label: 'Keep portfolio', onPressed: () => Navigator.pop(ctx, true)),
        AppButton(label: 'Delete portfolio', kind: AppButtonKind.danger, onPressed: () => Navigator.pop(ctx, false)),
      ],
      child: Text(
        'The API key is removed from this device straight away and syncing stops.\n\n'
        '• Keep portfolio: the synced transactions stay as an ordinary portfolio that you can edit.\n'
        '• Delete portfolio: the portfolio and its synced transactions are removed.\n\n'
        'Nothing changes in your Luno account. You may also revoke the key in Luno.',
        style: ctx.text.bodyMedium,
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  if (!choice) {
    final ok = await showAppConfirm(
      context,
      title: 'Delete the portfolio?',
      message: 'This removes "Luno – ${c.label}" and all of its synced transactions from this device.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
  }
  try {
    await ref.read(lunoConnectServiceProvider).disconnect(c.id, keepPortfolio: choice);
    ref.read(stepUpProvider.notifier).reset();
    if (!context.mounted) return;
    showAppToast(context, choice ? 'Disconnected. The portfolio was kept.' : 'Disconnected and deleted');
    context.go(Routes.luno);
  } on AppFailure catch (f) {
    if (context.mounted) showAppToast(context, '${AppErrorRetry.messageFor(f)} Nothing was changed.', error: true);
  }
}

/// Lists ledger entries Dashfolio could not interpret, so nothing is hidden silently.
Future<void> showUnrecognisedRows(BuildContext context, WidgetRef ref, LunoConnection c) async {
  final rows = await ref.read(lunoRepositoryProvider).stagedRows(c.id, states: {'unrecognised'});
  if (!context.mounted) return;
  await showAppModal<void>(
    context,
    builder: (ctx) => AppDialog(
      title: 'Entries that were not imported',
      actions: [AppTextButton(label: 'Close', onPressed: () => Navigator.pop(ctx))],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashfolio did not recognise these Luno ledger entries, so they are not part of your portfolio. '
            'Balances may differ from Luno until they are supported.',
            style: ctx.text.bodySmall,
          ),
          const SizedBox(height: AppSpace.s3),
          if (rows.isEmpty) const Text('None.'),
          for (final r in rows.take(100))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s2),
              child: Text(_describeRow(r.payloadJson, r.timestamp), style: ctx.text.bodyMedium),
            ),
        ],
      ),
    ),
  );
}

String _describeRow(String payloadJson, DateTime at) {
  try {
    final j = (jsonDecode(payloadJson) as Map).cast<String, Object?>();
    final description = '${j['description'] ?? ''}'.trim();
    return '${Fmt.date(at.toLocal())} · ${j['kind']} · ${j['balance_delta']} ${j['currency']}${description.isEmpty ? '' : ' · $description'}';
  } on Object {
    return Fmt.date(at.toLocal());
  }
}
