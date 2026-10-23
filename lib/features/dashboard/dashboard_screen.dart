import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/portfolio_providers.dart';
import '../../app/providers.dart';
import '../../app/refresh_controller.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/services/valuation.dart';
import '../../routing/routes.dart';
import '../common/page_scaffold.dart';
import '../holdings/holdings_table.dart';
import '../portfolios/portfolio_form.dart';
import '../transactions/transaction_form.dart';
import 'dashboard_cards.dart';
import 'dashboard_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfoliosAsync = ref.watch(portfoliosProvider);
    final txAsync = ref.watch(transactionsProvider);

    Widget body;
    if (portfoliosAsync.hasError || txAsync.hasError) {
      body = AppErrorRetry(error: portfoliosAsync.error ?? txAsync.error!, onRetry: () => ref.invalidate(portfoliosProvider));
    } else if (!portfoliosAsync.hasValue || !txAsync.hasValue) {
      body = const _DashboardSkeleton();
    } else {
      final active = ref.watch(activePortfoliosProvider);
      final txs = txAsync.value!;
      if (active.isEmpty) {
        body = Padding(
          padding: const EdgeInsets.only(top: AppSpace.s8),
          child: AppEmptyState(
            icon: AppIcon.folderOpen,
            title: 'Create your first portfolio',
            message: 'Group your holdings into portfolios, then add transactions or import a CSV from your broker.',
            actionLabel: 'Create portfolio',
            onAction: () => showPortfolioForm(context),
          ),
        );
      } else if (txs.isEmpty) {
        body = Padding(
          padding: const EdgeInsets.only(top: AppSpace.s8),
          child: AppEmptyState(
            icon: AppIcon.addChart,
            title: 'Add your first transaction',
            message: 'Record a purchase to see value, performance and allocation here.',
            actionLabel: 'Add transaction',
            onAction: () => showTransactionForm(context, portfolioId: active.first.id),
          ),
        );
      } else {
        body = const _DashboardBody();
      }
    }

    return PageScaffold(
      title: 'Dashboard',
      onRefresh: () => ref.read(refreshControllerProvider.notifier).refresh(),
      actions: [
        AppIconButton(
          icon: AppIcon.add,
          tooltip: 'Add transaction (Ctrl/Cmd+N)',
          onPressed: () => showTransactionForm(context, portfolioId: ref.read(selectedPortfolioProvider)),
        ),
      ],
      child: body,
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activePortfoliosProvider);
    final requested = ref.watch(selectedPortfolioProvider);
    final selected = active.any((p) => p.id == requested) ? requested : null;
    final valued = ref.watch(valuedPortfolioProvider(selected));
    final currency = ref.watch(appSettingsProvider.select((s) => s.baseCurrency));
    final refresh = ref.watch(refreshControllerProvider);
    final lastRefresh = ref.watch(appSettingsProvider.select((s) => s.lastRefreshAt));
    final txs = ref.watch(transactionsProvider).value ?? const <PortfolioTransaction>[];
    final names = {for (final p in active) p.id: p.name};
    final visibleTx = selected == null
        ? txs.where((t) => names.containsKey(t.portfolioId)).toList()
        : txs.where((t) => t.portfolioId == selected).toList();

    if (valued == null) return const _DashboardSkeleton();

    final title = selected == null ? 'All portfolios' : names[selected] ?? 'Portfolio';
    final anyMissing = valued.holdings.any((h) => h.priceMissing);
    final anyFxMissing = valued.holdings.any((h) => h.fxMissing);

    void openHolding(HoldingValuation h) {
      // Open within the portfolio when viewing one, else the first portfolio that holds it.
      final pid = selected ?? _firstPortfolioWith(ref, h.symbol) ?? active.first.id;
      context.push(Routes.holding(pid, h.symbol));
    }

    final hero = HeroCard(totals: valued.totals, currency: currency, title: title);
    final chart = ValueHistoryCard(portfolioId: selected, currency: currency);
    final alloc = AllocationCard(holdings: valued.holdings, currency: currency);
    final holdings = AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.s5, AppSpace.s5, AppSpace.s5, AppSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'Holdings',
            trailing: AppTextButton(
              label: 'View all',
              onPressed: () => context.go(selected == null ? Routes.portfolios : Routes.portfolio(selected)),
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          HoldingsTable(
            holdings: valued.holdings,
            baseCurrency: currency,
            limit: 8,
            onTap: openHolding,
            onAddTransaction: (h) => showTransactionForm(context, portfolioId: selected, symbol: h.symbol),
            emptyMessage: 'No open positions',
          ),
        ],
      ),
    );
    final movers = TopMoversCard(holdings: valued.holdings, onTap: openHolding);
    final recent = RecentTransactionsCard(
      transactions: visibleTx,
      portfolioNames: names,
      onTap: (t) => showTransactionForm(context, editing: t),
    );

    final proxyMissing = ref.watch(yahooConfigProvider).misconfigured;
    final banners = <Widget>[
      if (proxyMissing)
        InfoBanner(
          icon: AppIcon.cloudOff,
          warning: true,
          message: 'Prices need the Yahoo proxy on the web. Showing cached data only until a proxy URL is set.',
          actionLabel: 'Set up',
          onAction: () => context.go(Routes.settings),
        ),
      if (refresh.error != null)
        InfoBanner(
          icon: AppIcon.cloudOff,
          warning: true,
          message: lastRefresh == null
              ? '${AppErrorRetry.messageFor(refresh.error!)} No cached data yet.'
              : "Couldn't reach Yahoo — showing cached data from ${Fmt.time(lastRefresh.toLocal())}.",
          actionLabel: 'Retry',
          onAction: () => ref.read(refreshControllerProvider.notifier).refresh(),
        )
      else if (anyMissing)
        InfoBanner(
          icon: AppIcon.warning,
          warning: true,
          message: 'Some holdings have no price yet, so they are valued at cost.',
          actionLabel: 'Refresh',
          onAction: () => ref.read(refreshControllerProvider.notifier).refresh(),
        )
      else if (anyFxMissing)
        InfoBanner(
          icon: AppIcon.currencyExchange,
          warning: true,
          message: 'Some exchange rates are missing; those holdings are shown unconverted. Refresh to fetch FX rates.',
          actionLabel: 'Refresh',
          onAction: () => ref.read(refreshControllerProvider.notifier).refresh(),
        ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1100;
        final medium = c.maxWidth >= 760;
        const gap = AppSpace.s5;

        Widget selector = _PortfolioSelector(
          portfolios: active,
          selected: selected,
          onSelected: (id) => ref.read(selectedPortfolioProvider.notifier).select(id),
        );

        Widget layout;
        if (wide) {
          layout = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: chart),
                  const SizedBox(width: gap),
                  Expanded(flex: 4, child: alloc),
                ],
              ),
              const SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: holdings),
                  const SizedBox(width: gap),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        movers,
                        const SizedBox(height: gap),
                        recent,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        } else if (medium) {
          layout = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: gap),
              chart,
              const SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: alloc),
                  const SizedBox(width: gap),
                  Expanded(child: movers),
                ],
              ),
              const SizedBox(height: gap),
              holdings,
              const SizedBox(height: gap),
              recent,
            ],
          );
        } else {
          layout = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: gap),
              chart,
              const SizedBox(height: gap),
              alloc,
              const SizedBox(height: gap),
              holdings,
              const SizedBox(height: gap),
              movers,
              const SizedBox(height: gap),
              recent,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            selector,
            const SizedBox(height: AppSpace.s4),
            for (final b in banners) ...[b, const SizedBox(height: AppSpace.s4)],
            layout,
          ],
        );
      },
    );
  }

  int? _firstPortfolioWith(WidgetRef ref, String symbol) {
    final by = ref.read(transactionsByPortfolioProvider);
    for (final p in ref.read(activePortfoliosProvider)) {
      if ((by[p.id] ?? const []).any((t) => t.symbol == symbol)) return p.id;
    }
    return null;
  }
}

class _PortfolioSelector extends StatelessWidget {
  const _PortfolioSelector({required this.portfolios, required this.selected, required this.onSelected});

  final List<Portfolio> portfolios;
  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (portfolios.length < 2) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppChip(label: 'All portfolios', selected: selected == null, onTap: () => onSelected(null)),
          for (final p in portfolios) ...[
            const SizedBox(width: AppSpace.s2),
            AppChip(label: p.name, selected: selected == p.id, onTap: () => onSelected(p.id)),
          ],
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppCardSkeleton(height: 190),
      SizedBox(height: AppSpace.s5),
      AppCardSkeleton(height: 300, lines: 5),
      SizedBox(height: AppSpace.s5),
      AppCardSkeleton(height: 240),
    ],
  );
}
