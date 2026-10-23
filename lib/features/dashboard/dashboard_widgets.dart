import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/services/valuation.dart';
import '../common/page_scaffold.dart';
import '../common/small_widgets.dart';

/// Total value, day change and P&L breakdown.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.totals, required this.currency, required this.title});

  final PortfolioTotals totals;
  final String currency;
  final String title;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final t = totals;
    final stats = <Widget>[
      StatTile(
        label: 'Total return',
        value: Fmt.currency(t.totalReturn, currency, signed: true),
        valueColor: n.pnl(t.totalReturn.toDouble()),
        sub: Fmt.percent(t.totalReturnPct),
      ),
      StatTile(
        label: 'Unrealized',
        value: Fmt.currency(t.unrealized, currency, signed: true),
        valueColor: n.pnl(t.unrealized.toDouble()),
        sub: Fmt.percent(t.unrealizedPct),
      ),
      StatTile(label: 'Realized', value: Fmt.currency(t.realized, currency, signed: true), valueColor: n.pnl(t.realized.toDouble())),
      StatTile(label: 'Dividends', value: Fmt.currency(t.dividends, currency)),
      StatTile(label: 'Cost basis', value: Fmt.currency(t.costBasis, currency)),
      if (t.hasCash) StatTile(label: 'Cash', value: Fmt.currency(t.cash, currency)),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.labelMedium!.copyWith(color: n.textMuted)),
          const SizedBox(height: AppSpace.s2),
          Semantics(
            label: 'Total value ${Fmt.currency(t.value, currency)}',
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(Fmt.currency(t.value, currency), style: context.text.displayMedium),
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          Wrap(
            spacing: AppSpace.s3,
            runSpacing: AppSpace.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppChangeBadge(ratio: t.dayChangePct?.toDouble()),
              PnlText(amount: t.dayChange, currency: currency, showPercent: false, style: context.text.titleSmall),
              Text('today', style: context.text.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpace.s5),
          const AppDivider(),
          const SizedBox(height: AppSpace.s4),
          Wrap(spacing: AppSpace.s8, runSpacing: AppSpace.s4, children: stats),
        ],
      ),
    );
  }
}

/// Best and worst performers today.
class TopMoversCard extends StatelessWidget {
  const TopMoversCard({super.key, required this.holdings, required this.onTap});

  final List<HoldingValuation> holdings;
  final ValueChanged<HoldingValuation> onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final withChange = holdings.where((h) => h.dayChangePct != null && !h.priceMissing).toList()
      ..sort((a, b) => b.dayChangePct!.compareTo(a.dayChangePct!));
    final gainers = withChange.where((h) => h.dayChangePct! > Decimal.zero).take(3).toList();
    final losers = withChange.reversed.where((h) => h.dayChangePct! < Decimal.zero).take(3).toList();

    Widget row(HoldingValuation h) => AppPressable(
      onTap: () => onTap(h),
      semanticLabel: '${h.symbol} ${Fmt.percent(h.dayChangePct)}',
      minSize: const Size(0, 44),
      radius: AppSpace.radiusS,
      builder: (context, s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s1),
        child: Row(
          children: [
            SymbolBadge(h.symbol, size: 32),
            const SizedBox(width: AppSpace.s3),
            Expanded(child: Text(h.symbol, style: context.text.titleSmall)),
            AppChangeBadge(ratio: h.dayChangePct?.toDouble(), dense: true),
          ],
        ),
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Top movers today'),
          const SizedBox(height: AppSpace.s3),
          if (gainers.isEmpty && losers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
              child: Text('No price changes yet today', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
            )
          else ...[
            if (gainers.isNotEmpty) ...[Text('Gainers', style: context.text.labelSmall), ...gainers.map(row)],
            if (gainers.isNotEmpty && losers.isNotEmpty) const SizedBox(height: AppSpace.s2),
            if (losers.isNotEmpty) ...[Text('Losers', style: context.text.labelSmall), ...losers.map(row)],
          ],
        ],
      ),
    );
  }
}

/// Short list of the latest transactions.
class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key, required this.transactions, required this.portfolioNames, this.onTap, this.limit = 6});

  final List<PortfolioTransaction> transactions;
  final Map<int, String> portfolioNames;
  final ValueChanged<PortfolioTransaction>? onTap;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final items =
        ([...transactions]..sort((a, b) {
              final c = b.tradeDate.compareTo(a.tradeDate);
              return c != 0 ? c : b.id.compareTo(a.id);
            }))
            .take(limit)
            .toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Recent transactions'),
          const SizedBox(height: AppSpace.s2),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
              child: Text('No transactions yet', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
            ),
          for (final t in items)
            TransactionTile(tx: t, portfolioName: portfolioNames[t.portfolioId], onTap: onTap == null ? null : () => onTap!(t)),
        ],
      ),
    );
  }
}

Color txColor(AppTheme n, TxType t) => switch (t) {
  TxType.buy || TxType.openingPosition || TxType.deposit || TxType.transferIn => n.gain,
  TxType.sell || TxType.withdrawal || TxType.fee || TxType.transferOut => n.loss,
  TxType.dividend || TxType.reward => n.accent,
  TxType.split => n.textMuted,
};

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx, this.portfolioName, this.onTap});

  final PortfolioTransaction tx;
  final String? portfolioName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final t = tx;
    final title = t.symbol ?? t.type.label;
    final String detail = switch (t.type) {
      TxType.split => '${t.quantity.toString()}-for-${t.price.toString()} split',
      TxType.deposit || TxType.withdrawal => t.type.label,
      TxType.fee when t.symbol == null => t.type.label,
      TxType.dividend => '${t.quantity == Decimal.zero ? '' : '${Fmt.number(t.quantity)} × '}${Fmt.currency(t.price, t.currency)}',
      _ => '${Fmt.number(t.quantity, maxDecimals: 6)} @ ${Fmt.currency(t.price, t.currency)}',
    };
    final amount = switch (t.type) {
      TxType.split => null,
      TxType.dividend => (t.quantity == Decimal.zero ? t.price : t.gross),
      _ => t.gross,
    };
    return AppPressable(
      onTap: onTap,
      semanticLabel: '${t.type.label} $title on ${Fmt.date(t.tradeDate)}',
      minSize: const Size(0, 56),
      radius: AppSpace.radiusS,
      builder: (context, s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: txColor(n, t.type).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(
                t.type == TxType.openingPosition ? 'OPEN' : t.type.label.toUpperCase(),
                style: context.text.labelSmall!.copyWith(color: txColor(n, t.type), fontWeight: FontWeight.w800, fontSize: 10),
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (t.isSynced) ...[
                        const SizedBox(width: 4),
                        AppTooltip(
                          message: 'Synced from Luno',
                          child: AppIconView(AppIcon.lock, size: 12, color: n.textMuted),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    [detail, Fmt.shortDate(t.tradeDate), ?portfolioName].join(' · '),
                    style: context.text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (amount != null) AppMoneyText(amount, currency: t.currency, style: context.text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Info/warning strip shown above content.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, this.icon = AppIcon.info, this.warning = false, this.actionLabel, this.onAction});

  final String message;
  final AppIcon icon;
  final bool warning;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final color = warning ? n.warning : n.accent;
    return Semantics(
      liveRegion: true,
      child: AppSurface(
        shape: AppShape.inset,
        depth: 1,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
        child: Row(
          children: [
            AppIconView(icon, color: color, size: 20),
            const SizedBox(width: AppSpace.s3),
            Expanded(child: Text(message, style: context.text.bodyMedium)),
            if (actionLabel != null) ...[
              const SizedBox(width: AppSpace.s3),
              AppButton(label: actionLabel!, compact: true, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
