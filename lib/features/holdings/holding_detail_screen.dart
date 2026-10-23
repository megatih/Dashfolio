import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/portfolio_providers.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/services/holdings_engine.dart';
import '../../routing/routes.dart';
import '../charts/price_chart.dart';
import '../common/page_scaffold.dart';
import '../common/small_widgets.dart';
import '../markets/quote_chart_card.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transactions_list.dart';

/// Position detail: stats, lots, price chart with buy/sell markers and the symbol's transactions.
class HoldingDetailScreen extends ConsumerWidget {
  const HoldingDetailScreen({super.key, required this.portfolioId, required this.symbol});

  final int portfolioId;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = context.app;
    final leading = Padding(
      padding: const EdgeInsets.only(right: AppSpace.s3),
      child: AppIconButton(
        icon: AppIcon.arrowBack,
        tooltip: 'Back',
        onPressed: () => context.canPop() ? context.pop() : context.go(Routes.portfolio(portfolioId)),
      ),
    );
    final valued = ref.watch(valuedPortfolioProvider(portfolioId));
    final currency = ref.watch(appSettingsProvider.select((s) => s.baseCurrency));
    final txs = [...?ref.watch(transactionsByPortfolioProvider)[portfolioId]].where((t) => t.symbol == symbol).toList();
    final portfolio = ref.watch(portfoliosProvider).value?.where((p) => p.id == portfolioId).firstOrNull;

    if (valued == null) return PageScaffold(title: symbol, leading: leading, child: const AppCardSkeleton());

    final h = [...valued.holdings, ...valued.closed].where((h) => h.symbol == symbol).firstOrNull;
    if (h == null) {
      return PageScaffold(
        title: symbol,
        leading: leading,
        showRefresh: false,
        child: const Padding(
          padding: EdgeInsets.only(top: AppSpace.s8),
          child: AppEmptyState(
            icon: AppIcon.searchOff,
            title: 'No position found',
            message: 'This symbol has no transactions in this portfolio.',
          ),
        ),
      );
    }

    final positions = ref.watch(positionsProvider(portfolioId));
    final position = positions?.positions[symbol];
    final markers = [
      for (final t in txs)
        if (t.type == TxType.buy || t.type == TxType.sell || t.type == TxType.openingPosition)
          TradeMarker(date: t.tradeDate, isBuy: t.type != TxType.sell),
    ];
    final q = h.quote;
    final priceLocal = h.priceLocal;

    final stats = AppCard(
      child: Wrap(
        spacing: AppSpace.s8,
        runSpacing: AppSpace.s5,
        children: [
          StatTile(label: 'Quantity', value: Fmt.number(h.quantity, maxDecimals: 6)),
          StatTile(label: 'Avg cost', value: Fmt.currency(h.avgCostLocal, h.currency)),
          StatTile(label: 'Cost basis', value: Fmt.currency(h.costBase, currency)),
          StatTile(label: 'Market value', value: Fmt.currency(h.marketValueBase, currency)),
          StatTile(
            label: 'Unrealized',
            value: Fmt.currency(h.unrealizedBase, currency, signed: true),
            valueColor: n.pnl(h.unrealizedBase.toDouble()),
            sub: Fmt.percent(h.unrealizedPct),
          ),
          StatTile(
            label: 'Realized',
            value: Fmt.currency(h.realizedBase, currency, signed: true),
            valueColor: n.pnl(h.realizedBase.toDouble()),
          ),
          StatTile(label: 'Dividends', value: Fmt.currency(h.dividendsBase, currency)),
          if (h.quantity > Decimal.zero) StatTile(label: 'Weight', value: Fmt.percent(h.weight, signed: false, decimals: 1)),
        ],
      ),
    );

    return PageScaffold(
      title: symbol,
      leading: leading,
      actions: [
        AppIconButton(icon: AppIcon.showChart, tooltip: 'Open market page', onPressed: () => context.push(Routes.quote(symbol))),
        if (!ref.watch(lunoConnectionByPortfolioProvider).containsKey(portfolioId))
          AppIconButton(
            icon: AppIcon.add,
            tooltip: 'Add transaction',
            onPressed: () => showTransactionForm(context, portfolioId: portfolioId, symbol: symbol),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SymbolBadge(symbol, size: 48),
              const SizedBox(width: AppSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        if (priceLocal != null)
                          Flexible(
                            child: AppMoneyText(priceLocal, currency: h.currency, style: context.text.headlineSmall),
                          )
                        else
                          Text('No price', style: context.text.bodyMedium),
                        const SizedBox(width: AppSpace.s3),
                        AppChangeBadge(ratio: q?.changePct),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s5),
          stats,
          const SizedBox(height: AppSpace.s5),
          QuoteChartCard(
            symbol: symbol,
            currency: h.currency,
            markers: markers,
            initialRange: ChartRange.y1,
            ranges: const [ChartRange.m1, ChartRange.m6, ChartRange.ytd, ChartRange.y1, ChartRange.y5, ChartRange.max],
          ),
          const SizedBox(height: AppSpace.s5),
          if (position != null && position.lots.isNotEmpty)
            _LotsCard(position: position, method: portfolio?.costMethod ?? CostMethod.average),
          if (position != null && position.lots.isNotEmpty) const SizedBox(height: AppSpace.s5),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Transactions'),
                const SizedBox(height: AppSpace.s3),
                TransactionsList(transactions: txs, showFilters: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LotsCard extends StatelessWidget {
  const _LotsCard({required this.position, required this.method});

  final Position position;
  final CostMethod method;

  @override
  Widget build(BuildContext context) {
    final lots = position.lots;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(method == CostMethod.fifo ? 'Open lots (FIFO)' : 'Cost basis (average cost)'),
          const SizedBox(height: AppSpace.s3),
          if (method == CostMethod.average)
            Text(
              '${Fmt.number(position.quantity, maxDecimals: 6)} shares at an average of ${Fmt.currency(position.avgCostLocal, position.currency)} (total ${Fmt.currency(position.costLocal, position.currency)}).',
              style: context.text.bodyMedium,
            )
          else
            for (var i = 0; i < lots.length; i++) ...[
              if (i > 0) const AppDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
                child: Row(
                  children: [
                    Expanded(child: Text(Fmt.date(lots[i].date), style: context.text.bodyMedium)),
                    Expanded(
                      child: Text(
                        '${Fmt.number(lots[i].quantity, maxDecimals: 6)} sh',
                        style: context.text.bodyMedium,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '@ ${Fmt.currency(lots[i].unitCostLocal, position.currency)}',
                        style: context.text.bodyMedium,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        Fmt.currency(lots[i].costLocal, position.currency),
                        style: context.text.titleSmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
