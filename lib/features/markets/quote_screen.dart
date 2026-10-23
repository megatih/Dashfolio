import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/decimal_ext.dart';
import '../../core/format.dart';
import '../../core/result.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/luno.dart';
import '../../domain/entities/market.dart';
import '../../routing/routes.dart';
import '../common/page_scaffold.dart';
import '../common/small_widgets.dart';
import '../transactions/transaction_form.dart';
import 'quote_chart_card.dart';

/// Ensures a quote exists in the cache and is reasonably fresh.
final quoteEnsureProvider = FutureProvider.autoDispose.family<void, String>((ref, symbol) async {
  final repo = ref.read(marketDataRepositoryProvider);
  final cached = (await repo.quotesSnapshot())[symbol];
  final stale = cached == null || ref.read(clockProvider).now().difference(cached.fetchedAt) > const Duration(minutes: 5);
  if (!stale) return;
  final r = await repo.refreshQuotes([symbol]);
  if (r case Err(:final failure) when cached == null) throw failure;
});

final assetProfileProvider = FutureProvider.autoDispose.family<AssetProfile?, String>((ref, symbol) async {
  final r = await ref.read(marketDataRepositoryProvider).profile(symbol);
  return r.valueOrNull; // profile is optional (ETFs, FX, crypto often have none)
});

/// The user's fee schedule for a Luno pair; only available with a usable Luno connection.
final lunoFeeProvider = FutureProvider.autoDispose.family<LunoFeeInfo?, String>((ref, symbol) async {
  if (!ref.read(lunoSupportedProvider) || !isLunoSymbol(symbol)) return null;
  final connections = await ref.read(lunoRepositoryProvider).getConnections();
  if (!connections.any((c) => c.status.canSync)) return null;
  return (await ref.read(lunoMarketDataRepositoryProvider).feeInfo(symbol)).valueOrNull;
});

final newsProvider = FutureProvider.autoDispose.family<List<NewsItem>, String>((ref, symbol) async {
  final r = await ref.read(marketDataRepositoryProvider).search(symbol);
  return r.valueOrNull?.news ?? const [];
});

class QuoteScreen extends ConsumerWidget {
  const QuoteScreen({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leading = Padding(
      padding: const EdgeInsets.only(right: AppSpace.s3),
      child: AppIconButton(
        icon: AppIcon.arrowBack,
        tooltip: 'Back',
        onPressed: () => context.canPop() ? context.pop() : context.go(Routes.markets),
      ),
    );
    final ensure = ref.watch(quoteEnsureProvider(symbol));
    final quote = ref.watch(quotesProvider).value?[symbol];

    if (quote == null) {
      return PageScaffold(
        title: symbol,
        leading: leading,
        child: ensure.when(
          loading: () => const Column(
            children: [
              AppCardSkeleton(height: 120),
              SizedBox(height: AppSpace.s5),
              AppCardSkeleton(height: 320),
            ],
          ),
          error: (e, _) => AppErrorRetry(error: e, onRetry: () => ref.invalidate(quoteEnsureProvider(symbol))),
          data: (_) => Padding(
            padding: const EdgeInsets.only(top: AppSpace.s8),
            child: AppEmptyState(
              icon: AppIcon.searchOff,
              title: 'Symbol not found',
              message: isLunoSymbol(symbol) ? 'Luno has no market with this name.' : 'Yahoo Finance has no quote for this symbol.',
            ),
          ),
        ),
      );
    }

    final profile = ref.watch(assetProfileProvider(symbol)).value;
    final lists = ref.watch(watchlistsProvider).value ?? const [];
    final inLists = lists.where((w) => w.symbols.contains(symbol)).toList();

    return PageScaffold(
      title: symbol,
      leading: leading,
      actions: [
        AppMenuButton<int>(
          tooltip: 'Watchlists',
          icon: inLists.isEmpty ? AppIcon.star : AppIcon.starFilled,
          iconColor: inLists.isEmpty ? context.app.textMuted : context.app.warning,
          onSelected: (id) async {
            final repo = ref.read(portfolioRepositoryProvider);
            if (id == -1) {
              final nid = await repo.createWatchlist('My watchlist');
              await repo.addToWatchlist(nid, symbol);
              return;
            }
            final w = lists.firstWhere((w) => w.id == id);
            if (w.symbols.contains(symbol)) {
              await repo.removeFromWatchlist(id, symbol);
            } else {
              await repo.addToWatchlist(id, symbol);
            }
          },
          items: [
            for (final w in lists) AppMenuItem(w.id, w.name, checked: w.symbols.contains(symbol)),
            if (lists.isEmpty) const AppMenuItem(-1, 'Create watchlist and add'),
          ],
        ),
        AppIconButton(
          icon: AppIcon.add,
          tooltip: 'Add to portfolio',
          onPressed: () => showTransactionForm(context, symbol: symbol),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(quote: quote),
          const SizedBox(height: AppSpace.s5),
          QuoteChartCard(symbol: symbol, currency: quote.currency),
          const SizedBox(height: AppSpace.s5),
          if (isLunoSymbol(symbol)) _LunoStats(quote: quote) else _KeyStats(quote: quote, profile: profile),
          if (profile != null) ...[const SizedBox(height: AppSpace.s5), _ProfileCard(profile: profile)],
          const SizedBox(height: AppSpace.s5),
          _NewsCard(symbol: symbol),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.quote});
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final q = quote;
    final open = q.marketState == 'REGULAR';
    final change = q.change;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SymbolBadge(q.symbol, size: 52),
          const SizedBox(width: AppSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.name ?? q.symbol, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text([q.symbol, ?q.exchange, q.currency].join(' · '), style: context.text.bodySmall),
                const SizedBox(height: AppSpace.s3),
                Wrap(
                  spacing: AppSpace.s3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      label: 'Price ${Fmt.price(q.price)} ${q.currency}',
                      child: Text(q.price == null ? '—' : Fmt.currency(dec(q.price), q.currency), style: context.text.displayMedium),
                    ),
                    AppChangeBadge(ratio: q.changePct),
                    if (change != null)
                      Text(
                        Fmt.currency(dec(change), q.currency, signed: true),
                        style: context.text.bodyMedium!.copyWith(color: n.pnl(change)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.s2),
                if (q.marketState != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIconView(AppIcon.circle, size: 8, color: open ? n.gain : n.textMuted),
                      const SizedBox(width: 6),
                      Text(_stateLabel(q.marketState!, q.quoteType), style: context.text.labelMedium!.copyWith(color: n.textMuted)),
                      const SizedBox(width: 10),
                      Text('as of ${Fmt.time(q.fetchedAt.toLocal())}', style: context.text.bodySmall),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stateLabel(String state, String? type) {
    // Crypto and FX trade around the clock; "closed" would be misleading.
    if (type == 'CRYPTOCURRENCY' || type == 'CURRENCY') return '24/7 market';
    return switch (state) {
      'REGULAR' => 'Market open',
      'PRE' || 'PREPRE' => 'Pre-market',
      'POST' || 'POSTPOST' => 'After hours',
      _ => 'Market closed',
    };
  }
}

/// Order-book facts for a Luno market: best bid/ask, spread, 24 h volume, status and (when connected) your fees.
class _LunoStats extends ConsumerWidget {
  const _LunoStats({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = quote;
    String p(double? v) => v == null ? '—' : Fmt.price(v, decimals: v.abs() < 1 ? 6 : 2);
    final bid = q.bid, ask = q.ask;
    final spread = bid != null && ask != null ? ask - bid : null;
    final mid = bid != null && ask != null ? (ask + bid) / 2 : null;
    final fee = ref.watch(lunoFeeProvider(q.symbol)).value;
    String pct(Decimal d) => Fmt.percent(d, signed: false, decimals: 2);
    final base = lunoPairOf(q.symbol).substring(0, lunoPairOf(q.symbol).length - 3);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Luno market'),
          const SizedBox(height: AppSpace.s4),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s5,
            children: [
              StatTile(label: 'Bid', value: p(bid)),
              StatTile(label: 'Ask', value: p(ask)),
              StatTile(
                label: 'Spread',
                value: spread == null ? '—' : p(spread),
                sub: spread != null && mid != null && mid > 0 ? pct(dec(spread / mid)) : null,
              ),
              StatTile(label: 'Previous close (UTC)', value: p(q.previousClose)),
              StatTile(label: 'Day range', value: '${p(q.dayLow)} – ${p(q.dayHigh)}'),
              StatTile(label: '24h volume', value: q.volume == null ? '—' : '${Fmt.compact(q.volume)} $base'),
              StatTile(
                label: 'Status',
                value: switch (q.marketState) {
                  'REGULAR' => 'Trading',
                  'POSTONLY' => 'Post-only',
                  'DISABLED' => 'Disabled',
                  _ => '—',
                },
              ),
              if (fee != null) ...[
                StatTile(label: 'Maker fee', value: pct(fee.makerFeeBuy), sub: 'your 30-day tier'),
                StatTile(label: 'Taker fee', value: pct(fee.takerFeeBuy)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyStats extends StatelessWidget {
  const _KeyStats({required this.quote, required this.profile});

  final Quote quote;
  final AssetProfile? profile;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    String p(double? v) => v == null ? '—' : Fmt.price(v, decimals: v.abs() < 1 ? 4 : 2);
    final pe = q.trailingPE ?? profile?.trailingPE;
    final eps = q.eps ?? profile?.eps;
    final dy = q.dividendYield ?? profile?.dividendYield;
    final beta = q.beta ?? profile?.beta;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Key statistics'),
          const SizedBox(height: AppSpace.s4),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s5,
            children: [
              StatTile(label: 'Open', value: p(q.open)),
              StatTile(label: 'Previous close', value: p(q.previousClose)),
              StatTile(label: 'Day range', value: '${p(q.dayLow)} – ${p(q.dayHigh)}'),
              StatTile(label: '52-week range', value: '${p(q.fiftyTwoWeekLow)} – ${p(q.fiftyTwoWeekHigh)}'),
              StatTile(label: 'Volume', value: Fmt.compact(q.volume)),
              StatTile(label: 'Market cap', value: Fmt.compact(q.marketCap)),
              StatTile(label: 'P/E (TTM)', value: pe == null ? '—' : pe.toStringAsFixed(2)),
              StatTile(label: 'EPS (TTM)', value: p(eps)),
              StatTile(label: 'Dividend yield', value: dy == null ? '—' : Fmt.percent(dec(dy), signed: false)),
              StatTile(label: 'Beta', value: beta == null ? '—' : beta.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.profile});
  final AssetProfile profile;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final p = widget.profile;
    final e = p.events;
    final facts = <(String, String)>[
      if (p.sector != null) ('Sector', p.sector!),
      if (p.industry != null) ('Industry', p.industry!),
      if (p.country != null) ('Country', p.country!),
      if (p.employees != null) ('Employees', Fmt.number(dec(p.employees), maxDecimals: 0)),
    ];
    final events = <(String, DateTime)>[
      if (e.exDividendDate != null) ('Ex-dividend', e.exDividendDate!),
      if (e.dividendPayDate != null) ('Dividend pay date', e.dividendPayDate!),
      if (e.earningsDate != null) ('Earnings', e.earningsDate!),
    ];
    if (p.description == null && facts.isEmpty && events.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Profile'),
          const SizedBox(height: AppSpace.s3),
          if (facts.isNotEmpty)
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s4,
              children: [for (final f in facts) StatTile(label: f.$1, value: f.$2)],
            ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s5),
            Text('Upcoming events', style: context.text.labelMedium!.copyWith(color: n.textMuted)),
            const SizedBox(height: AppSpace.s2),
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s4,
              children: [for (final ev in events) StatTile(label: ev.$1, value: Fmt.date(ev.$2))],
            ),
          ],
          if (p.description != null) ...[
            const SizedBox(height: AppSpace.s5),
            Text(
              p.description!,
              style: context.text.bodyMedium,
              maxLines: _expanded ? null : 4,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: AppTextButton(onPressed: () => setState(() => _expanded = !_expanded), label: _expanded ? 'Show less' : 'Read more'),
            ),
          ],
          if (p.website != null)
            Align(
              alignment: Alignment.centerLeft,
              child: AppTextButton(
                onPressed: () => launchUrl(Uri.parse(p.website!), mode: LaunchMode.externalApplication),
                icon: AppIcon.openInNew,
                label: Uri.tryParse(p.website!)?.host ?? p.website!,
              ),
            ),
        ],
      ),
    );
  }
}

class _NewsCard extends ConsumerWidget {
  const _NewsCard({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = context.app;
    final news = ref.watch(newsProvider(symbol));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('News'),
          const SizedBox(height: AppSpace.s2),
          news.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.s4),
              child: AppSkeleton(height: 48),
            ),
            error: (_, _) => Text('News is unavailable right now.', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
                    child: Text('No recent news.', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const AppDivider(),
                        AppPressable(
                          onTap: () => launchUrl(Uri.parse(items[i].url), mode: LaunchMode.externalApplication),
                          semanticLabel: '${items[i].title}, ${items[i].publisher ?? ''}',
                          minSize: const Size(0, 56),
                          radius: AppSpace.radiusS,
                          builder: (context, s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(items[i].title, style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          ?items[i].publisher,
                                          if (items[i].publishedAt != null) Fmt.date(items[i].publishedAt!.toLocal()),
                                        ].join(' · '),
                                        style: context.text.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                AppIconView(AppIcon.openInNew, size: 16, color: n.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
