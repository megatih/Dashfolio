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

/// Settings → Luno: every connection, its status, and the entry to add another.
class LunoConnectionsScreen extends ConsumerWidget {
  const LunoConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(lunoConnectionsProvider);
    return PageScaffold(
      title: 'Luno',
      subtitle: 'Read-only sync of your Luno account',
      showRefresh: false,
      leading: lunoBackButton(context),
      actions: [
        AppButton(label: 'Connect', icon: AppIcon.addLink, kind: AppButtonKind.primary, onPressed: () => context.push(Routes.lunoConnect)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('How it works'),
                const SizedBox(height: AppSpace.s2),
                Text(
                  'Each Luno API key becomes a read-only portfolio that mirrors your balances, trades, deposits, withdrawals, sends, receives and interest. '
                  'The key is kept in your device\'s secure storage, can only read, and is never included in backups. '
                  'Data from Luno stays on this device.',
                  style: context.text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          switch (connections) {
            AsyncData(:final value) when value.isEmpty => AppEmptyState(
              icon: AppIcon.currencyBitcoin,
              title: 'No Luno account connected',
              message: 'Create a read-only API key in Luno and connect it to see your crypto next to the rest of your portfolio.',
              actionLabel: 'Connect Luno',
              onAction: () => context.push(Routes.lunoConnect),
            ),
            AsyncData(:final value) => Column(children: [for (final c in value) _ConnectionCard(c)]),
            AsyncError(:final error) => AppErrorRetry(error: error, onRetry: () => ref.invalidate(lunoConnectionsProvider)),
            _ => const Padding(
              padding: EdgeInsets.all(AppSpace.s6),
              child: Center(child: AppSpinner()),
            ),
          },
        ],
      ),
    );
  }
}

class _ConnectionCard extends ConsumerWidget {
  const _ConnectionCard(this.c);

  final LunoConnection c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncing = c.status == LunoConnectionStatus.syncing;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s3),
      child: AppCard(
        onTap: () => context.push(Routes.lunoConnection(c.id)),
        semanticLabel: 'Luno connection ${c.label}, ${c.status.label}',
        child: Row(
          children: [
            const AppIconView(AppIcon.currencyBitcoin, size: 28),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.label, style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: AppSpace.s3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LunoStatusChip(c.status),
                      Text(lunoSyncedText(c), style: context.text.bodySmall),
                      Text('Key …${c.keyIdHint}', style: context.text.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: AppIcon.sync,
              tooltip: 'Sync now',
              loading: syncing,
              onPressed: syncing || !c.status.canSync ? null : () => runLunoSync(context, ref, c),
            ),
            const AppIconView(AppIcon.chevronRight),
          ],
        ),
      ),
    );
  }
}
