import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/result.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/market.dart';
import 'small_widgets.dart';

/// Debounced Yahoo symbol search with an inline results list.
class SymbolSearchField extends ConsumerStatefulWidget {
  const SymbolSearchField({
    super.key,
    required this.onSelected,
    this.label,
    this.hint = 'Search symbol or company',
    this.autofocus = false,
    this.initialQuery,
    this.maxResults = 6,
    this.debounce = const Duration(milliseconds: 300),
    this.onNewsLoaded,
    this.errorText,
  });

  final ValueChanged<SearchResult> onSelected;
  final String? label;
  final String hint;
  final bool autofocus;
  final String? initialQuery;
  final int maxResults;
  final Duration debounce;
  final ValueChanged<List<NewsItem>>? onNewsLoaded;
  final String? errorText;

  @override
  ConsumerState<SymbolSearchField> createState() => _SymbolSearchFieldState();
}

class _SymbolSearchFieldState extends ConsumerState<SymbolSearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);
  Timer? _timer;
  List<SearchResult> _results = const [];
  bool _loading = false;
  String? _error;
  int _seq = 0;
  int _highlight = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _timer = Timer(widget.debounce, () => _search(q));
  }

  Future<void> _search(String q) async {
    final seq = ++_seq;
    final r = await ref.read(marketDataRepositoryProvider).search(q);
    if (!mounted || seq != _seq) return; // a newer query superseded this one
    setState(() {
      _loading = false;
      switch (r) {
        case Ok(:final value):
          _results = value.results.take(widget.maxResults).toList();
          _error = null;
          _highlight = 0;
          widget.onNewsLoaded?.call(value.news);
        case Err(:final failure):
          _results = const [];
          _error = failure.message;
      }
    });
  }

  void _pick(SearchResult r) {
    widget.onSelected(r);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _results.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlight = (_highlight + 1) % _results.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _highlight = (_highlight - 1 + _results.length) % _results.length);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          onKeyEvent: _onKey,
          child: AppTextField(
            controller: _controller,
            label: widget.label,
            hint: widget.hint,
            prefixIcon: AppIcon.search,
            autofocus: widget.autofocus,
            errorText: widget.errorText,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (_) {
              if (_results.isNotEmpty) _pick(_results[_highlight.clamp(0, _results.length - 1)]);
            },
            suffix: _loading ? const SizedBox(width: 16, height: 16, child: AppSpinner(strokeWidth: 2)) : null,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s2),
            child: Text(_error!, style: context.text.bodySmall!.copyWith(color: n.loss)),
          ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s2),
            child: AppSurface(
              shape: AppShape.flat,
              radius: AppSpace.radiusM,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _results.length; i++)
                    _ResultTile(result: _results[i], highlighted: i == _highlight, onTap: () => _pick(_results[i])),
                ],
              ),
            ),
          )
        else if (!_loading && _controller.text.trim().isNotEmpty && _error == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s3),
            child: Text('No matches', style: context.text.bodySmall),
          ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.highlighted, required this.onTap});

  final SearchResult result;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final sub = [if (result.quoteType != null) _prettyType(result.quoteType!), if (result.exchange != null) result.exchange!].join(' · ');
    return AppPressable(
      onTap: onTap,
      semanticLabel: '${result.symbol}, ${result.name}',
      minSize: const Size(0, 56),
      radius: AppSpace.radiusS,
      builder: (context, s) => Container(
        color: highlighted || s.hovered ? n.accent.withValues(alpha: 0.08) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
        child: Row(
          children: [
            SymbolBadge(result.symbol, size: 36),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(result.symbol, style: context.text.titleSmall),
                  Text(result.name, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (sub.isNotEmpty) Text(sub, style: context.text.labelSmall),
          ],
        ),
      ),
    );
  }

  static String _prettyType(String t) => switch (t.toUpperCase()) {
    'EQUITY' => 'Stock',
    'ETF' => 'ETF',
    'MUTUALFUND' => 'Fund',
    'CRYPTOCURRENCY' => 'Crypto',
    'CURRENCY' => 'FX',
    'INDEX' => 'Index',
    'FUTURE' => 'Future',
    _ => t,
  };
}
