import 'package:flutter/cupertino.dart';

import 'cu_surface.dart';
import 'cupertino_theme.dart';

/// Marks widgets that are children of a [CuSection]; fields and selects render as inline rows instead of filled wells.
class CuSectionScope extends InheritedWidget {
  const CuSectionScope({super.key, required super.child});

  static bool of(BuildContext context) => context.getInheritedWidgetOfExactType<CuSectionScope>() != null;

  @override
  bool updateShouldNotify(CuSectionScope oldWidget) => false;
}

/// A child of a [CuSection] that draws its own padding and tap area edge to edge.
abstract interface class CuFullBleed {}

/// An inset-grouped section: the header sits above the box, rows are separated by hairlines, an optional footer sits below.
class CuSection extends StatelessWidget {
  const CuSection({super.key, required this.children, this.title, this.footer, this.trailing});

  final String? title;
  final String? footer;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final inset = m.pointer ? 12.0 : CupertinoMetrics.inset;
    final rows = <Widget>[];
    for (final (i, c) in children.indexed) {
      if (i > 0) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(left: inset),
            child: SizedBox(height: 0.5, child: ColoredBox(color: p.separator)),
          ),
        );
      }
      rows.add(
        c is CuFullBleed
            ? c
            : ConstrainedBox(
                constraints: BoxConstraints(minHeight: m.pointer ? 36 : m.rowHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: inset, vertical: m.pointer ? 6 : 8),
                  child: Align(alignment: Alignment.centerLeft, child: c),
                ),
              ),
      );
    }
    final header = title == null
        ? null
        : Padding(
            padding: EdgeInsets.only(left: m.pointer ? 2 : inset, right: m.pointer ? 2 : inset, bottom: m.pointer ? 6 : 8),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title!, style: m.pointer ? t.headline : t.footnote.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
                ?trailing,
              ],
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        CuSectionScope(
          child: Container(
            decoration: BoxDecoration(
              color: p.secondaryGroupedBackground,
              borderRadius: BorderRadius.circular(m.groupRadius),
              border: m.pointer ? Border.all(color: p.separator, width: 0.5) : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
          ),
        ),
        if (footer != null)
          Padding(
            padding: EdgeInsets.fromLTRB(m.pointer ? 2 : inset, 8, m.pointer ? 2 : inset, 0),
            child: Text(footer!, style: t.footnote),
          ),
      ],
    );
  }
}

/// A label (and optional description) with a trailing control. A wide control moves under the label on narrow widths.
class CuFormRow extends StatelessWidget {
  const CuFormRow({super.key, required this.label, required this.control, this.description, this.wide = false});

  final String label;
  final String? description;
  final Widget control;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = CupertinoTypography.of(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: t.body),
        if (description != null) Text(description!, style: t.footnote),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (wide && c.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              text,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: control),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: c.maxWidth * (wide ? 0.7 : 0.55)),
              child: control,
            ),
          ],
        );
      },
    );
  }
}

/// A full-width tappable row inside a section: an accent label with an optional leading symbol.
class CuActionRow extends StatelessWidget implements CuFullBleed {
  const CuActionRow({super.key, required this.label, this.icon, this.onTap, this.destructive = false, this.loading = false});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool destructive;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final enabled = onTap != null && !loading;
    final color = !enabled ? p.tertiaryLabel : (destructive ? p.loss : p.accent);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: CuTappable(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: m.pointer ? 36 : m.rowHeight, minWidth: double.infinity),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: m.pointer ? 12 : CupertinoMetrics.inset, vertical: 8),
            child: Row(
              children: [
                if (loading)
                  CupertinoActivityIndicator(radius: m.iconSize / 2)
                else if (icon != null)
                  Icon(icon, size: m.iconSize + 4, color: color),
                if (loading || icon != null) const SizedBox(width: 10),
                Flexible(
                  child: Text(label, style: t.body.copyWith(color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom control with a label in a row beside it (inside a section) and an optional error line.
class CuField extends StatelessWidget {
  const CuField({super.key, required this.label, required this.child, this.errorText});

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final inSection = CuSectionScope.of(context);
    final labelText = Text(label, style: inSection ? t.body : t.footnote.copyWith(fontWeight: FontWeight.w500));
    final error = errorText == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(errorText!, style: t.footnote.copyWith(color: p.loss)),
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (inSection)
          Row(
            children: [
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 140), child: labelText),
              const SizedBox(width: 12),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: child),
              ),
            ],
          )
        else ...[
          Padding(padding: const EdgeInsets.only(bottom: 6, left: 2), child: labelText),
          child,
        ],
        ?error,
      ],
    );
  }
}
