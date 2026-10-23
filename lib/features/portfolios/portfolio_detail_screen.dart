import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/portfolio_providers.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/services/valuation.dart';
import '../../routing/routes.dart';
import '../common/page_scaffold.dart';
import '../dashboard/dashboard_cards.dart';
import '../holdings/holdings_table.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transactions_list.dart';
import '../luno/luno_widgets.dart';
import 'portfolio_form.dart';
import 'portfolios_screen.dart';

enum _Tab { holdings, transactions, allocation }

class PortfolioDetailScreen extends ConsumerStatefulWidget {
  const PortfolioDetailScreen({super.key, required this.portfolioId});

  final int portfolioId;

  @override
  ConsumerState<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends ConsumerState<PortfolioDetailScreen> {
  _Tab _tab = _Tab.holdings;

  @override
  Widget build(BuildContext context) {
    final portfolios = ref.watch(portfoliosProvider);
    final portfolio = portfolios.value?.where((p) => p.id == widget.portfolioId).firstOrNull;
    final leading = Padding(
      padding: const EdgeInsets.only(right: AppSpace.s3),
      child: AppIconButton(icon: AppIcon.arrowBack, tooltip: 'Back to portfolios', onPressed: () => context.go(Routes.portfolios)),
    );

    if (!portfolios.hasValue) {
      return PageScaffold(title: 'Portfolio', leading: leading, child: const AppCardSkeleton());
    }
    if (portfolio == null) {
      return PageScaffold(
        title: 'Portfolio',
        leading: leading,
        showRefresh: false,
        child: const Padding(
          padding: EdgeInsets.only(top: AppSpace.s8),
          child: AppEmptyState(icon: AppIcon.searchOff, title: 'Portfolio not found', message: 'It may have been deleted.'),
        ),
      );
    }

    final valued = ref.watch(valuedPortfolioProvider(portfolio.id));
    final currency = ref.watch(appSettingsProvider.select((s) => s.baseCurrency));
    final txs = ref.watch(transactionsByPortfolioProvider)[portfolio.id] ?? const <PortfolioTransaction>[];
    final luno = ref.watch(lunoConnectionByPortfolioProvider)[portfolio.id];

    Widget content;
    if (valued == null) {
      content = const AppCardSkeleton();
    } else {
      content = switch (_tab) {
        _Tab.holdings => _HoldingsTab(
          portfolio: portfolio,
          valued: valued,
          currency: currency,
          hasTransactions: txs.isNotEmpty,
          synced: luno != null,
        ),
        _Tab.transactions => AppCard(
          child: txs.isEmpty
              ? AppEmptyState(
                  icon: AppIcon.receipt,
                  title: 'No transactions',
                  message: luno == null ? null : 'Nothing has been synced from Luno yet.',
                  actionLabel: luno == null ? 'Add transaction' : null,
                  onAction: luno == null ? () => showTransactionForm(context, portfolioId: portfolio.id) : null,
                  compact: true,
                )
              : TransactionsList(transactions: txs),
        ),
        _Tab.allocation => AllocationCard(holdings: valued.holdings, currency: currency),
      };
    }

    return PageScaffold(
      title: portfolio.name,
      leading: leading,
      actions: [
        AppIconButton(
          icon: AppIcon.edit,
          tooltip: 'Edit portfolio',
          onPressed: () => showPortfolioForm(context, editing: portfolio),
        ),
        if (luno == null)
          AppIconButton(
            icon: AppIcon.add,
            tooltip: 'Add transaction',
            onPressed: () => showTransactionForm(context, portfolioId: portfolio.id),
          )
        else
          AppIconButton(icon: AppIcon.link, tooltip: 'Luno connection', onPressed: () => context.push(Routes.lunoConnection(luno.id))),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (luno != null) ...[LunoPortfolioBadge(luno), const SizedBox(height: AppSpace.s2)],
          if (valued != null) ...[
            totalsSummary(context, valued.totals.value, valued.totals.dayChange, valued.totals.dayChangePct, currency),
            const SizedBox(height: AppSpace.s1),
            Text(
              'Total return ${Fmt.currency(valued.totals.totalReturn, currency, signed: true)} (${Fmt.percent(valued.totals.totalReturnPct)}) · ${portfolio.costMethod.label}',
              style: context.text.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpace.s4),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AppSegmented<_Tab>(
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
                segments: const [
                  AppSegment(_Tab.holdings, 'Holdings'),
                  AppSegment(_Tab.transactions, 'Transactions'),
                  AppSegment(_Tab.allocation, 'Allocation'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          content,
        ],
      ),
    );
  }
}

class _HoldingsTab extends StatelessWidget {
  const _HoldingsTab({
    required this.portfolio,
    required this.valued,
    required this.currency,
    required this.hasTransactions,
    this.synced = false,
  });

  final Portfolio portfolio;
  final ValuedPortfolio valued;
  final String currency;
  final bool hasTransactions;
  final bool synced;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    if (!hasTransactions) {
      return AppCard(
        child: AppEmptyState(
          icon: AppIcon.addChart,
          title: synced ? 'Nothing synced yet' : 'Add your first transaction',
          message: synced ? 'Sync your Luno connection to fill this portfolio.' : 'Record a purchase to build this portfolio.',
          actionLabel: synced ? null : 'Add transaction',
          onAction: synced ? null : () => showTransactionForm(context, portfolioId: portfolio.id),
          compact: true,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s4, AppSpace.s4, AppSpace.s2),
          child: HoldingsTable(
            holdings: valued.holdings,
            baseCurrency: currency,
            onTap: (h) => context.push(Routes.holding(portfolio.id, h.symbol)),
            onAddTransaction: synced ? null : (h) => showTransactionForm(context, portfolioId: portfolio.id, symbol: h.symbol),
          ),
        ),
        if (valued.closed.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s5),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Closed positions'),
                const SizedBox(height: AppSpace.s2),
                for (final h in valued.closed)
                  AppRow(
                    title: h.symbol,
                    titleStyle: context.text.titleSmall,
                    subtitle: h.name,
                    subtitleStyle: context.text.bodySmall,
                    trailing: PnlTextRealized(amount: h.realizedBase, currency: currency, color: n.pnl(h.realizedBase.toDouble())),
                    onTap: () => context.push(Routes.holding(portfolio.id, h.symbol)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PnlTextRealized extends StatelessWidget {
  const PnlTextRealized({super.key, required this.amount, required this.currency, required this.color});

  final Decimal amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(Fmt.currency(amount, currency, signed: true), style: context.text.titleSmall!.copyWith(color: color)),
      Text('realized', style: context.text.labelSmall),
    ],
  );
}
