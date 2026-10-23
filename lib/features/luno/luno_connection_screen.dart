import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/luno.dart';
import '../../routing/routes.dart';
import '../common/page_scaffold.dart';
import 'luno_actions.dart';
import 'luno_widgets.dart';

/// One Luno connection: status, warnings, and everything you can do to it.
class LunoConnectionScreen extends ConsumerWidget {
  const LunoConnectionScreen({super.key, required this.connectionId});

  final int connectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(lunoConnectionsProvider);
    final c = connections.value?.where((x) => x.id == connectionId).firstOrNull;
    final back = lunoBackButton(context, to: Routes.luno);
    if (c == null) {
      return PageScaffold(
        title: 'Luno',
        showRefresh: false,
        leading: back,
        child: connections.isLoading
            ? const Center(child: AppSpinner())
            : AppEmptyState(
                icon: AppIcon.linkOff,
                title: 'Connection not found',
                actionLabel: 'Back to Luno',
                onAction: () => context.go(Routes.luno),
              ),
      );
    }
    final n = context.app;
    final syncing = c.status == LunoConnectionStatus.syncing;

    Widget card(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s4),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(title),
            const SizedBox(height: AppSpace.s3),
            ...children,
          ],
        ),
      ),
    );

    return PageScaffold(
      title: c.label,
      subtitle: 'Luno connection',
      showRefresh: false,
      leading: back,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card('Status', [
            Wrap(
              spacing: AppSpace.s4,
              runSpacing: AppSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                LunoStatusChip(c.status),
                Text(lunoSyncedText(c), style: context.text.bodyMedium),
                Text('Key …${c.keyIdHint}', style: context.text.bodyMedium),
                Text('Values in ${c.homeFiat}', style: context.text.bodyMedium),
              ],
            ),
            if (c.status == LunoConnectionStatus.revoked) ...[
              const SizedBox(height: AppSpace.s3),
              LunoNotice(
                icon: AppIcon.keyOff,
                color: n.loss,
                child: Text(
                  'Luno rejected this key; it was probably revoked or deleted. Your synced data is kept. Replace the key to resume syncing.',
                  style: context.text.bodyMedium,
                ),
              ),
            ] else if (c.status == LunoConnectionStatus.credentialsMissing) ...[
              const SizedBox(height: AppSpace.s3),
              LunoNotice(
                icon: AppIcon.vpnKey,
                color: n.warning,
                child: Text(
                  'There is no API key on this device for this connection (for example after restoring a backup). '
                  'Keys are never included in backups. Enter a key to resume syncing.',
                  style: context.text.bodyMedium,
                ),
              ),
            ] else if (c.status == LunoConnectionStatus.needsReview && c.lastError != null) ...[
              const SizedBox(height: AppSpace.s3),
              LunoNotice(
                icon: AppIcon.rule,
                color: n.warning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Balances differ from Luno', style: context.text.titleSmall),
                    const SizedBox(height: 4),
                    Text(c.lastError!, style: context.text.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Dashfolio does not invent transactions to hide a difference. This usually clears after the next sync. If it stays, some ledger entries are not understood yet.',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ] else if (c.lastError != null) ...[
              const SizedBox(height: AppSpace.s3),
              LunoNotice(
                icon: AppIcon.info,
                color: c.status == LunoConnectionStatus.error ? n.loss : n.textMuted,
                child: Text(c.lastError!),
              ),
            ],
          ]),
          if (c.writePermWarning)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s4),
              child: AppCard(
                child: LunoNotice(
                  icon: AppIcon.warningOutlined,
                  color: n.warning,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This key might be able to send funds', style: context.text.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Dashfolio can confirm a key cannot trade or withdraw, but it cannot test "Send to any address" without moving money. '
                        'Check the key in Luno. If it has that permission, replace it with a custom key that only has the view permissions.',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: AppSpace.s3),
                      AppButton(
                        label: 'I checked: it has no send permission',
                        compact: true,
                        onPressed: () => ref.read(lunoRepositoryProvider).updateConnection(c.copyWith(writePermWarning: false)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          card('Actions', [
            Wrap(
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s3,
              children: [
                AppButton(
                  label: 'Sync now',
                  icon: AppIcon.sync,
                  kind: AppButtonKind.primary,
                  loading: syncing,
                  onPressed: syncing || !c.status.canSync ? null : () => runLunoSync(context, ref, c),
                ),
                AppButton(label: 'Open portfolio', icon: AppIcon.pieChart, onPressed: () => context.go(Routes.portfolio(c.portfolioId))),
                AppButton(label: 'Rename', icon: AppIcon.edit, onPressed: () => renameConnection(context, ref, c)),
                AppButton(label: 'Currency', icon: AppIcon.currencyExchange, onPressed: () => changeHomeFiat(context, ref, c)),
                AppButton(label: 'Replace key', icon: AppIcon.vpnKey, onPressed: () => replaceKey(context, ref, c)),
              ],
            ),
            if (c.unrecognisedRows > 0) ...[
              const SizedBox(height: AppSpace.s4),
              LunoNotice(
                icon: AppIcon.helpOutline,
                color: n.warning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${c.unrecognisedRows} ledger entries were not recognised', style: context.text.titleSmall),
                    const SizedBox(height: 4),
                    Text('They are listed for review and are not part of the portfolio.', style: context.text.bodySmall),
                    const SizedBox(height: AppSpace.s2),
                    Wrap(
                      spacing: AppSpace.s3,
                      children: [
                        AppButton(label: 'Review', compact: true, onPressed: () => showUnrecognisedRows(context, ref, c)),
                        AppButton(label: 'Rebuild from history', compact: true, onPressed: () => rebuildFromHistory(context, ref, c)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ]),
          card('Remove', [
            Text(
              'Disconnecting deletes the API key from this device. Nothing changes in your Luno account.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpace.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Disconnect',
                icon: AppIcon.linkOff,
                kind: AppButtonKind.danger,
                onPressed: () => disconnectConnection(context, ref, c),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
