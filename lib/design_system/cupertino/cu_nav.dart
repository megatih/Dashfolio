import 'package:flutter/cupertino.dart';

import 'cu_buttons.dart';
import 'cu_surface.dart';
import 'cupertino_theme.dart';

class CuNavItem {
  const CuNavItem({required this.label, required this.icon, required this.selectedIcon});
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The iPhone tab bar: translucent, blurred bar with the system icon and label sizes.
class CuTabBar extends StatelessWidget {
  const CuTabBar({super.key, required this.items, required this.selectedIndex, required this.onSelected});

  final List<CuNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => CupertinoTabBar(
    currentIndex: selectedIndex,
    onTap: onSelected,
    items: [for (final i in items) BottomNavigationBarItem(icon: Icon(i.icon), activeIcon: Icon(i.selectedIcon), label: i.label)],
  );
}

/// Tells pages whether the sidebar is hidden and how to toggle it, so the toolbar can show the sidebar button.
class CuSidebarScope extends InheritedWidget {
  const CuSidebarScope({super.key, required this.hidden, required this.onToggle, required super.child});

  final bool hidden;
  final VoidCallback onToggle;

  static CuSidebarScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<CuSidebarScope>();

  @override
  bool updateShouldNotify(CuSidebarScope oldWidget) => hidden != oldWidget.hidden;
}

/// A source-list sidebar. It is either shown or hidden (never a narrow icon rail); the toggle lives in its header and, when
/// hidden, in the page toolbar.
class CuSideNav extends StatelessWidget {
  const CuSideNav({super.key, required this.items, required this.selectedIndex, required this.onSelected, this.header, this.trailing});

  final List<CuNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? header;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final m = CupertinoMetrics.current;
    final scope = CuSidebarScope.maybeOf(context);
    if (scope?.hidden ?? false) return const SizedBox.shrink();
    final panel = Container(
      decoration: BoxDecoration(
        color: p.sidebarBackground,
        border: Border(right: BorderSide(color: p.separator, width: 0.5)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: m.pointer ? 8 : 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 12),
                child: Row(
                  children: [
                    if (header != null) Flexible(child: header!) else const Spacer(),
                    if (scope != null) ...[
                      const SizedBox(width: 8),
                      CuIconButton(
                        icon: CupertinoIcons.sidebar_left,
                        tooltip: 'Hide sidebar',
                        iconSize: m.navIconSize - 2,
                        size: m.pointer ? 28 : 40,
                        color: p.secondaryLabel,
                        onPressed: scope.onToggle,
                      ),
                    ],
                  ],
                ),
              ),
              for (var i = 0; i < items.length; i++) ...[
                _Item(item: items[i], selected: i == selectedIndex, onTap: () => onSelected(i)),
                const SizedBox(height: 2),
              ],
              const Spacer(),
              ?trailing,
            ],
          ),
        ),
      ),
    );
    // On macOS the sidebar is as wide as its widest row (nav labels or the header), never narrower than the minimum.
    // Touch devices use the fixed source-list width.
    return m.pointer
        ? ConstrainedBox(
            constraints: BoxConstraints(minWidth: m.sidebarWidth),
            child: IntrinsicWidth(child: panel),
          )
        : SizedBox(width: m.sidebarWidth, child: panel);
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.selected, required this.onTap});

  final CuNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    return CuPressable(
      onTap: onTap,
      semanticLabel: item.label,
      selected: selected,
      minSize: Size(0, m.pointer ? 32 : m.rowHeight),
      builder: (context, s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (m.pointer ? p.fill : p.accent.withValues(alpha: 0.14)) : (s.hovered ? p.quaternaryFill : null),
          borderRadius: BorderRadius.circular(m.pointer ? 6 : 10),
          border: s.focused ? Border.all(color: p.accent.withValues(alpha: 0.6), width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(selected ? item.selectedIcon : item.icon, size: m.iconSize + 4, color: p.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (selected && !m.pointer ? t.body.copyWith(fontWeight: FontWeight.w600) : t.body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-screen page background with an optional bottom bar.
class CuScaffold extends StatelessWidget {
  const CuScaffold({super.key, required this.body, this.bottomBar});

  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoPalette.of(context).groupedBackground,
    resizeToAvoidBottomInset: false,
    child: Column(
      children: [
        Expanded(child: body),
        ?bottomBar,
      ],
    ),
  );
}

/// Page chrome. On touch devices: a large-title navigation bar that collapses on scroll, with pull-to-refresh. On macOS: an
/// inline toolbar (title and status on the left, actions on the right) above the content.
class CuPage extends StatefulWidget {
  const CuPage({
    super.key,
    required this.title,
    required this.child,
    required this.contentMaxWidth,
    required this.compactBelow,
    this.subtitle,
    this.status,
    this.actions = const [],
    this.refreshAction,
    this.progress,
    this.leading,
    this.padBody = true,
    this.scrollable = true,
    this.onRefresh,
  });

  final String title;
  final Widget child;
  final double contentMaxWidth;
  final double compactBelow;
  final String? subtitle;
  final Widget? status;
  final List<Widget> actions;
  final Widget? refreshAction;
  final Widget? progress;
  final Widget? leading;
  final bool padBody;
  final bool scrollable;
  final Future<void> Function()? onRefresh;

  @override
  State<CuPage> createState() => _CuPageState();
}

class _CuPageState extends State<CuPage> {
  bool _scrolled = false;

  Widget? _sidebarButton(BuildContext context) {
    final scope = CuSidebarScope.maybeOf(context);
    if (scope == null || !scope.hidden) return null;
    final m = CupertinoMetrics.current;
    return CuIconButton(
      icon: CupertinoIcons.sidebar_left,
      tooltip: 'Show sidebar',
      iconSize: m.navIconSize,
      color: CupertinoPalette.of(context).accent,
      onPressed: scope.onToggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = CupertinoMetrics.pageMargin(width);
    final sidebar = _sidebarButton(context);
    final leading = widget.leading ?? sidebar;
    // Pull-to-refresh is the touch idiom, so the refresh button is only shown without it.
    final trailingItems = [...widget.actions, if (!(widget.onRefresh != null && !m.pointer)) ?widget.refreshAction];
    final trailing = trailingItems.isEmpty ? null : Row(mainAxisSize: MainAxisSize.min, children: trailingItems);

    Widget centered(Widget w) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.contentMaxWidth),
        child: w,
      ),
    );
    Widget body(Widget child) =>
        centered(widget.padBody ? Padding(padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24), child: child) : child);
    final headerLine = widget.status ?? (widget.subtitle == null ? null : Text(widget.subtitle!, style: t.footnote));

    if (m.pointer) {
      final toolbar = LayoutBuilder(
        builder: (context, c) => Container(
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: gutter),
          decoration: BoxDecoration(
            color: p.groupedBackground,
            border: Border(bottom: BorderSide(color: _scrolled ? p.separator : const Color(0x00000000), width: 0.5)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 8)],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(widget.title, style: t.title2, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    if (headerLine != null && c.maxWidth > 560) ...[const SizedBox(width: 12), Flexible(child: headerLine)],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      );
      final content = widget.scrollable
          ? NotificationListener<ScrollNotification>(
              onNotification: (n) {
                final scrolled = n.metrics.pixels > 1;
                if (n.depth == 0 && scrolled != _scrolled) setState(() => _scrolled = scrolled);
                return false;
              },
              child: SingleChildScrollView(child: body(widget.child)),
            )
          : body(widget.child);
      return CupertinoPageScaffold(
        backgroundColor: p.groupedBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toolbar,
            ?widget.progress,
            Expanded(child: content),
          ],
        ),
      );
    }

    if (!widget.scrollable) {
      return CupertinoPageScaffold(
        backgroundColor: p.groupedBackground,
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          transitionBetweenRoutes: false,
          backgroundColor: p.barBackground,
          leading: leading,
          middle: Semantics(header: true, child: Text(widget.title)),
          trailing: trailing,
        ),
        child: SafeArea(
          child: Column(
            children: [
              ?widget.progress,
              Expanded(child: body(widget.child)),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: p.groupedBackground,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            transitionBetweenRoutes: false,
            leading: leading,
            largeTitle: Semantics(header: true, child: Text(widget.title)),
            trailing: trailing,
            backgroundColor: p.barBackground,
          ),
          if (widget.onRefresh != null) CupertinoSliverRefreshControl(onRefresh: widget.onRefresh),
          if (widget.progress != null)
            SliverToBoxAdapter(
              child: centered(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: widget.progress,
                ),
              ),
            ),
          if (headerLine != null)
            SliverToBoxAdapter(
              child: centered(
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 4),
                  child: Align(alignment: Alignment.centerLeft, child: headerLine),
                ),
              ),
            ),
          SliverToBoxAdapter(child: body(widget.child)),
        ],
      ),
    );
  }
}

class CuSectionHeader extends StatelessWidget {
  const CuSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = CupertinoTypography.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(title, style: t.headline)),
        ),
        ?trailing,
      ],
    );
  }
}
