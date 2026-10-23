import 'package:flutter/cupertino.dart';

import 'cu_buttons.dart';
import 'cu_surface.dart';
import 'cupertino_theme.dart';

class CuSkeleton extends StatefulWidget {
  const CuSkeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<CuSkeleton> createState() => _CuSkeletonState();
}

class _CuSkeletonState extends State<CuSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: p.secondaryFill.withValues(alpha: 0.4 + 0.6 * _c.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

class CuCardSkeleton extends StatelessWidget {
  const CuCardSkeleton({super.key, this.height = 160, this.lines = 3});

  final double height;
  final int lines;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: CuSurface(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CuSkeleton(width: 120, height: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < lines; i++) ...[
            CuSkeleton(height: 12, width: i == lines - 1 ? 180 : double.infinity),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}

class CuErrorRetry extends StatelessWidget {
  const CuErrorRetry({super.key, required this.message, required this.icon, this.onRetry, this.compact = false});

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 28 : 40, color: p.secondaryLabel),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: t.body),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                CuTextButton(label: 'Retry', icon: CupertinoIcons.refresh, onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CuEmptyState extends StatelessWidget {
  const CuEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 36 : 48, color: p.secondaryLabel),
              SizedBox(height: compact ? 12 : 20),
              Text(title, textAlign: TextAlign.center, style: t.title2),
              if (message != null) ...[const SizedBox(height: 6), Text(message!, textAlign: TextAlign.center, style: t.subheadline)],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                CuButton(label: actionLabel!, kind: CuButtonKind.primary, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A list row: leading, title/subtitle, trailing; tappable when [onTap] is set.
class CuRow extends StatelessWidget {
  const CuRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleStyle,
    this.subtitleStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: CupertinoMetrics.current.rowHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: titleStyle ?? t.body),
                  if (subtitle != null) Text(subtitle!, style: subtitleStyle ?? t.footnote),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (onTap != null && trailing == null) ...[
              const SizedBox(width: 4),
              Icon(CupertinoIcons.chevron_right, size: CupertinoMetrics.current.iconSize - 4, color: p.tertiaryLabel),
            ],
          ],
        ),
      ),
    );
    return onTap == null ? row : CuTappable(onTap: onTap, child: row);
  }
}

/// A read-only grid of text (header row and string rows).
class CuSimpleTable extends StatelessWidget {
  const CuSimpleTable({super.key, required this.headers, required this.rows, this.headerStyle, this.cellStyle});

  final List<String> headers;
  final List<List<String>> rows;
  final TextStyle? headerStyle;
  final TextStyle? cellStyle;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    Widget cell(String s, TextStyle? st) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(s, style: st, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder(horizontalInside: BorderSide(color: p.separator, width: 0.5)),
        children: [
          TableRow(children: [for (final h in headers) cell(h, headerStyle)]),
          for (final r in rows) TableRow(children: [for (var i = 0; i < headers.length; i++) cell(i < r.length ? r[i] : '', cellStyle)]),
        ],
      ),
    );
  }
}
