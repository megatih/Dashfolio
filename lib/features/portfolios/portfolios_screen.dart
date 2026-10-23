import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/portfolio_providers.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/portfolio.dart';
import '../../routing/routes.dart';
import '../luno/luno_actions.dart';
import '../luno/luno_widgets.dart';
import '../charts/value_history_chart.dart';
import '../common/page_scaffold.dart';
import 'portfolio_form.dart';

class PortfoliosScreen extends ConsumerWidget {
  const PortfoliosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfoliosProvider);
    return PageScaffold(
      title: 'Portfolios',
      actions: [AppIconButton(icon: AppIcon.add, tooltip: 'New portfolio', onPressed: () => showPortfolioForm(context))],
      child: async.when(
        loading: () => const Column(
          children: [
            AppCardSkeleton(),
            SizedBox(height: AppSpace.s4),
            AppCardSkeleton(),
          ],
        ),
        error: (e, _) => AppErrorRetry(error: e, onRetry: () => ref.invalidate(portfoliosProvider)),
        data: (all) {
          if (all.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpace.s8),
              child: AppEmptyState(
                icon: AppIcon.folderOpen,
                title: 'No portfolios yet',
                message: 'Create a portfolio to start tracking holdings.',
                actionLabel: 'Create portfolio',
                onAction: () => showPortfolioForm(context),
              ),
            );
          }
          final active = all.where((p) => !p.archived).toList();
          final archived = all.where((p) => p.archived).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppReorderableList(
                itemCount: active.length,
                onReorder: (oldIndex, newIndex) {
                  final ids = active.map((p) => p.id).toList();
                  final moved = ids.removeAt(oldIndex);
                  ids.insert(newIndex, moved);
                  ref.read(portfolioRepositoryProvider).reorderPortfolios(ids);
                },
                itemBuilder: (context, i) => Padding(
                  key: ValueKey(active[i].id),
                  padding: const EdgeInsets.only(bottom: AppSpace.s4),
                  child: _PortfolioCard(portfolio: active[i], index: i, reorderable: active.length > 1),
                ),
              ),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: AppSpace.s4),
                Text('Archived', style: context.text.titleSmall),
                const SizedBox(height: AppSpace.s3),
                for (final p in archived)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s3),
                    child: _ArchivedTile(portfolio: p),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PortfolioCard extends ConsumerWidget {
  const _PortfolioCard({required this.portfolio, required this.index, required this.reorderable});

  final Portfolio portfolio;
  final int index;
  final bool reorderable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = context.app;
    final valued = ref.watch(valuedPortfolioProvider(portfolio.id));
    final currency = ref.watch(appSettingsProvider.select((s) => s.baseCurrency));
    final spark = ref.watch(valueHistoryProvider(HistoryKey(portfolio.id, HistoryRange.m1))).value;
    final t = valued?.totals;

    return AppCard(
      onTap: () => context.go(Routes.portfolio(portfolio.id)),
      semanticLabel: 'Open portfolio ${portfolio.name}',
      child: Row(
        children: [
          Container(
            width: 6,
            height: 56,
            decoration: BoxDecoration(color: Color(portfolio.color), borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: AppSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(portfolio.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (portfolio.description != null)
                  Text(portfolio.description!, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpace.s1),
                Text('${portfolio.costMethod.label} · ${valued?.holdings.length ?? 0} holdings', style: context.text.labelSmall),
                if (ref.watch(lunoConnectionByPortfolioProvider)[portfolio.id] case final c?)
                  Padding(padding: const EdgeInsets.only(top: 2), child: LunoPortfolioBadge(c)),
              ],
            ),
          ),
          // The trend line is a nicety; drop it on narrow screens so the value never gets squeezed.
          if (spark != null && spark.points.length > 1 && MediaQuery.sizeOf(context).width >= 640) ...[
            Sparkline(values: [for (final p in spark.points) p.value]),
            const SizedBox(width: AppSpace.s4),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (t != null) ...[
                AppMoneyText(t.value, currency: currency, style: context.text.titleMedium),
                const SizedBox(height: 2),
                AppChangeBadge(ratio: t.dayChangePct?.toDouble(), dense: true, filled: false),
              ] else
                const AppSkeleton(width: 80),
            ],
          ),
          AppMenuButton<String>(
            tooltip: 'Portfolio actions',
            iconColor: n.textMuted,
            onSelected: (v) => _action(context, ref, v),
            items: const [AppMenuItem('edit', 'Edit'), AppMenuItem('archive', 'Archive'), AppMenuItem('delete', 'Delete')],
          ),
          if (reorderable)
            ReorderableDragStartListener(
              index: index,
              child: Semantics(
                label: 'Drag to reorder',
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AppIconView(AppIcon.dragHandle, color: n.textMuted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _action(BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(portfolioRepositoryProvider);
    switch (action) {
      case 'edit':
        await showPortfolioForm(context, editing: portfolio);
      case 'archive':
        await repo.updatePortfolio(portfolio.copyWith(archived: true));
        if (context.mounted) showAppToast(context, '${portfolio.name} archived');
      case 'delete':
        final connection = ref.read(lunoConnectionByPortfolioProvider)[portfolio.id];
        if (connection != null) {
          // A synced portfolio is owned by its Luno connection: removing it must also delete the API key.
          await disconnectConnection(context, ref, connection);
          return;
        }
        final ok = await showAppConfirm(
          context,
          title: 'Delete "${portfolio.name}"?',
          message: 'This permanently deletes the portfolio and all of its transactions.',
          confirmLabel: 'Delete portfolio',
          destructive: true,
        );
        if (ok) await repo.deletePortfolio(portfolio.id);
    }
  }
}

class _ArchivedTile extends ConsumerWidget {
  const _ArchivedTile({required this.portfolio});
  final Portfolio portfolio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: 0.8,
      child: AppSurface(
        shape: AppShape.inset,
        depth: 1,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
        child: Row(
          children: [
            Expanded(child: Text(portfolio.name, style: context.text.titleSmall)),
            AppTextButton(
              label: 'Restore',
              onPressed: () => ref.read(portfolioRepositoryProvider).updatePortfolio(portfolio.copyWith(archived: false)),
            ),
            AppTextButton(
              label: 'Delete',
              destructive: true,
              onPressed: () async {
                final connection = ref.read(lunoConnectionByPortfolioProvider)[portfolio.id];
                if (connection != null) {
                  await disconnectConnection(context, ref, connection);
                  return;
                }
                final ok = await showAppConfirm(
                  context,
                  title: 'Delete "${portfolio.name}"?',
                  message: 'This permanently deletes the portfolio and all of its transactions.',
                  confirmLabel: 'Delete portfolio',
                  destructive: true,
                );
                if (ok) await ref.read(portfolioRepositoryProvider).deletePortfolio(portfolio.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared summary line used on detail screens.
Widget totalsSummary(BuildContext context, Decimal value, Decimal dayChange, Decimal? dayPct, String currency) => Wrap(
  spacing: AppSpace.s3,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    AppMoneyText(value, currency: currency, style: context.text.headlineMedium),
    AppChangeBadge(ratio: dayPct?.toDouble()),
    Text(
      Fmt.currency(dayChange, currency, signed: true),
      style: context.text.bodySmall!.copyWith(color: context.app.pnl(dayChange.toDouble())),
    ),
  ],
);
