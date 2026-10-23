import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import 'app_theme.dart';

/// ▲/▼ + signed percent. Direction is conveyed by the arrow as well as color.
class AppChangeBadge extends StatelessWidget {
  const AppChangeBadge({super.key, required this.ratio, this.dense = false, this.filled = true});

  /// Change as a ratio (0.0123 = +1.23%). Null renders an em dash.
  final double? ratio;
  final bool dense;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final a = context.app;
    final r = ratio;
    final color = r == null ? a.textMuted : a.pnl(r);
    final arrow = r == null || r == 0 ? '' : (r > 0 ? '▲ ' : '▼ ');
    final text = r == null ? '—' : '$arrow${Fmt.percent(Decimal.parse(r.toStringAsFixed(6)), signed: false)}';
    final style = (dense ? context.text.labelSmall : context.text.labelMedium)!.copyWith(color: color, fontWeight: FontWeight.w700);
    final label = r == null
        ? 'No change data'
        : '${r >= 0 ? 'Up' : 'Down'} ${Fmt.percent(Decimal.parse(r.abs().toStringAsFixed(6)), signed: false)}';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 2 : 3),
        decoration: filled ? BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)) : null,
        child: Text(text, style: style),
      ),
    );
  }
}

/// Currency amount in tabular figures, optionally colored by sign.
class AppMoneyText extends StatelessWidget {
  const AppMoneyText(
    this.amount, {
    super.key,
    required this.currency,
    this.style,
    this.signed = false,
    this.colored = false,
    this.compact = false,
    this.textAlign,
  });

  final Decimal? amount;
  final String currency;
  final TextStyle? style;
  final bool signed;
  final bool colored;
  final bool compact;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.text.bodyMedium!;
    final v = amount;
    if (v == null) return Text('—', style: base, textAlign: textAlign);
    final color = colored ? context.app.pnl(v.toDouble()) : base.color;
    return Text(
      Fmt.currency(v, currency, signed: signed, compact: compact),
      style: base.copyWith(color: color, fontFeatures: tabularFigures),
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
