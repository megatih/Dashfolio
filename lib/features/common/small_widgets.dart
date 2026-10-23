import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';

/// Circle with the first letters of a symbol.
class SymbolBadge extends StatelessWidget {
  const SymbolBadge(this.symbol, {super.key, this.size = 40});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final text = symbol.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final label = text.isEmpty ? '?' : text.substring(0, text.length.clamp(1, 2)).toUpperCase();
    return ExcludeSemantics(
      child: AppSurface(
        shape: AppShape.inset,
        depth: 1,
        circle: true,
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.text.labelMedium!.copyWith(color: n.accent, fontSize: size * 0.3),
        ),
      ),
    );
  }
}

/// Signed amount with percentage, colored by direction (e.g. "+$120.50 (+1.2%)").
class PnlText extends StatelessWidget {
  const PnlText({
    super.key,
    required this.amount,
    required this.currency,
    this.ratio,
    this.style,
    this.showPercent = true,
    this.compact = false,
  });

  final Decimal amount;
  final String currency;
  final Decimal? ratio;
  final TextStyle? style;
  final bool showPercent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final color = n.pnl(amount.toDouble());
    final base = (style ?? context.text.bodyMedium!).copyWith(color: color, fontFeatures: tabularFigures);
    final amt = Fmt.currency(amount, currency, signed: true, compact: compact);
    final pct = showPercent && ratio != null ? ' (${Fmt.percent(ratio)})' : '';
    return Text('$amt$pct', style: base, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

/// Small label/value pair used in stat grids.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.valueColor, this.sub});

  final String label;
  final String value;
  final Color? valueColor;
  final String? sub;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: context.text.labelSmall),
      const SizedBox(height: 2),
      Text(
        value,
        style: context.text.titleSmall!.copyWith(color: valueColor, fontFeatures: tabularFigures),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      if (sub != null) Text(sub!, style: context.text.bodySmall),
    ],
  );
}
