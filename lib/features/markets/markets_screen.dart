import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/decimal_ext.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/market.dart';
import '../../domain/entities/portfolio.dart';
import '../../routing/routes.dart';
import '../common/page_scaffold.dart';
import '../common/small_widgets.dart';
import '../common/symbol_search.dart';

class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key, this.watchlistId});

  final int? watchlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(watchlistsProvider);
    return PageScaffold(
      title: 'Markets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SymbolSearchField(
            hint: 'Search stocks, ETFs, crypto, FX…  (Ctrl/Cmd+K)',
            onSelected: (r) => context.push(Routes.quote(r.symbol)),
          ),
          const SizedBox(height: AppSpace.s6),
          lists.when(
            loading: () => const AppCardSkeleton(),
            error: (e, _) => AppErrorRetry(error: e, onRetry: () => ref.invalidate(watchlistsProvider)),
            data: (all) => _Watchlists(all: all, selectedId: watchlistId),
          ),
        ],
      ),
    );
  }
}

class _Watchlists extends ConsumerWidget {
  const _Watchlists({required this.all, required this.selectedId});

  final List<Watchlist> all;
  final int? selectedId;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _askName(context, title: 'New watchlist', initial: all.isEmpty ? 'My watchlist' : '');
    if (name == null) return;
    final id = await ref.read(portfolioRepositoryProvider).createWatchlist(name);
    if (context.mounted) context.go(Routes.watchlist(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (all.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: AppIcon.visibility,
          title: 'Track what you are watching',
          message: 'Create a watchlist to follow symbols you do not own yet.',
          actionLabel: 'Create watchlist',
          onAction: () => _create(context, ref),
          compact: true,
        ),
      );
    }
    final current = all.where((w) => w.id == selectedId).firstOrNull ?? all.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final w in all) ...[
                AppChip(label: w.name, selected: w.id == current.id, onTap: () => context.go(Routes.watchlist(w.id))),
                const SizedBox(width: AppSpace.s2),
              ],
              AppChip(label: 'New', icon: AppIcon.add, onTap: () => _create(context, ref)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s4),
        _WatchlistCard(list: current),
      ],
    );
  }
}

Future<String?> _askName(BuildContext context, {required String title, String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showAppModal<String>(
    context,
    builder: (ctx) => AppDialog(
      title: title,
      actions: [
        AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
        AppButton(
          label: 'Save',
          kind: AppButtonKind.primary,
          onPressed: () {
            final v = controller.text.trim();
            if (v.isNotEmpty) Navigator.pop(ctx, v);
          },
        ),
      ],
      child: AppTextField(
        controller: controller,
        label: 'Name',
        autofocus: true,
        onSubmitted: (v) => v.trim().isNotEmpty ? Navigator.pop(ctx, v.trim()) : null,
      ),
    ),
  );
}

class _WatchlistCard extends ConsumerWidget {
  const _WatchlistCard({required this.list});

  final Watchlist list;

  Future<void> _addSymbol(BuildContext context, WidgetRef ref) async {
    await showAppDialog<void>(
      context,
      title: 'Add to ${list.name}',
      // The dialog lives on the root navigator, so it must be closed with its own context.
      child: Builder(
        builder: (dialogContext) => SymbolSearchField(
          autofocus: true,
          onSelected: (r) async {
            final repo = ref.read(portfolioRepositoryProvider);
            await repo.addToWatchlist(list.id, r.symbol);
            ref.read(marketDataRepositoryProvider).refreshQuotes([r.symbol]);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = context.app;
    final quotes = ref.watch(quotesProvider).value ?? const <String, Quote>{};
    final repo = ref.read(portfolioRepositoryProvider);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s4, AppSpace.s4, AppSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2),
            child: SectionTitle(
              list.name,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(icon: AppIcon.add, tooltip: 'Add symbol', size: 40, onPressed: () => _addSymbol(context, ref)),
                  AppMenuButton<String>(
                    tooltip: 'Watchlist actions',
                    iconColor: n.textMuted,
                    onSelected: (v) async {
                      if (v == 'rename') {
                        final name = await _askName(context, title: 'Rename watchlist', initial: list.name);
                        if (name != null) await repo.renameWatchlist(list.id, name);
                      } else if (v == 'delete') {
                        final ok = await showAppConfirm(
                          context,
                          title: 'Delete "${list.name}"?',
                          message: 'The watchlist is removed; your holdings are not affected.',
                          confirmLabel: 'Delete',
                          destructive: true,
                        );
                        if (ok) {
                          await repo.deleteWatchlist(list.id);
                          if (context.mounted) context.go(Routes.markets);
                        }
                      }
                    },
                    items: const [AppMenuItem('rename', 'Rename'), AppMenuItem('delete', 'Delete')],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          if (list.symbols.isEmpty)
            AppEmptyState(
              icon: AppIcon.search,
              title: 'This watchlist is empty',
              message: 'Search for a symbol to add it.',
              actionLabel: 'Add symbol',
              onAction: () => _addSymbol(context, ref),
              compact: true,
            )
          else ...[
            const _WatchHeader(),
            AppReorderableList(
              itemCount: list.symbols.length,
              onReorder: (o, nIdx) {
                final order = [...list.symbols];
                order.insert(nIdx, order.removeAt(o));
                repo.reorderWatchlistItems(list.id, order);
              },
              itemBuilder: (context, i) {
                final s = list.symbols[i];
                return _WatchRow(
                  key: ValueKey(s),
                  index: i,
                  symbol: s,
                  quote: quotes[s],
                  onRemove: () => repo.removeFromWatchlist(list.id, s),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _WatchHeader extends StatelessWidget {
  const _WatchHeader();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final style = context.text.labelMedium!.copyWith(color: context.app.textMuted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.app.outline)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Symbol', style: style)),
          Expanded(
            flex: 2,
            child: Text('Price', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text('Change', style: style, textAlign: TextAlign.right),
          ),
          if (wide) ...[
            Expanded(
              flex: 3,
              child: Text('Day range', style: style, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: 2,
              child: Text('Volume', style: style, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: 2,
              child: Text('Mkt cap', style: style, textAlign: TextAlign.right),
            ),
          ],
          const SizedBox(width: 88),
        ],
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({super.key, required this.index, required this.symbol, required this.quote, required this.onRemove});

  final int index;
  final String symbol;
  final Quote? quote;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final q = quote;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final ccy = q?.currency ?? 'USD';
    String money(double? v) => v == null ? '—' : Fmt.price(v, decimals: v.abs() < 1 ? 4 : 2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (d) async {
        final choice = await showAppMenu<String>(
          context,
          position: d.globalPosition,
          items: const [AppMenuItem('open', 'Open'), AppMenuItem('remove', 'Remove from watchlist')],
        );
        if (!context.mounted) return;
        if (choice == 'open') context.push(Routes.quote(symbol));
        if (choice == 'remove') onRemove();
      },
      child: Semantics(
        button: true,
        label:
            '$symbol ${q?.name ?? ''} ${q?.price == null ? 'no price' : Fmt.price(q!.price)} ${Fmt.percent(q?.changePct == null ? null : dec(q!.changePct!))}',
        child: AppTappable(
          onTap: () => context.push(Routes.quote(symbol)),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: n.outline.withValues(alpha: 0.6))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      SymbolBadge(symbol, size: 34),
                      const SizedBox(width: AppSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(symbol, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(q?.name ?? '—', style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    q?.price == null ? '—' : '${Fmt.price(q!.price, decimals: q.price!.abs() < 1 ? 4 : 2)} ${ccy == 'USD' ? '' : ccy}',
                    style: context.text.titleSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppChangeBadge(ratio: q?.changePct, dense: true),
                      if (q?.change != null)
                        Text(Fmt.price(q!.change!.abs(), decimals: q.change!.abs() < 1 ? 4 : 2), style: context.text.bodySmall),
                    ],
                  ),
                ),
                if (wide) ...[
                  Expanded(
                    flex: 3,
                    child: Text(
                      q == null ? '—' : '${money(q.dayLow)} – ${money(q.dayHigh)}',
                      style: context.text.bodyMedium,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(Fmt.compact(q?.volume), style: context.text.bodyMedium, textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(Fmt.compact(q?.marketCap), style: context.text.bodyMedium, textAlign: TextAlign.right),
                  ),
                ],
                SizedBox(
                  width: 88,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppInlineIconButton(icon: AppIcon.close, tooltip: 'Remove $symbol', color: n.textMuted, onPressed: onRemove),
                      ReorderableDragStartListener(
                        index: index,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: AppIconView(AppIcon.dragHandle, size: 20, color: n.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
