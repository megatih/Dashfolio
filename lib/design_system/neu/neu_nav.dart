import 'package:flutter/material.dart';

import 'neu_surface.dart';
import 'tokens.dart';

class NeuNavItem {
  const NeuNavItem({required this.label, required this.icon, IconData? selectedIcon}) : selectedIcon = selectedIcon ?? icon;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Bottom navigation for compact widths.
class NeuNavBar extends StatelessWidget {
  const NeuNavBar({super.key, required this.items, required this.selectedIndex, required this.onSelected});

  final List<NeuNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(NeuTheme.s3, NeuTheme.s2, NeuTheme.s3, NeuTheme.s3),
        child: NeuSurface(
          depth: 3,
          radius: NeuTheme.radiusL,
          padding: const EdgeInsets.symmetric(horizontal: NeuTheme.s2, vertical: NeuTheme.s2),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: NeuPressable(
                    onTap: () => onSelected(i),
                    semanticLabel: items[i].label,
                    selected: i == selectedIndex,
                    minSize: const Size(48, 52),
                    builder: (context, s) {
                      final sel = i == selectedIndex;
                      return NeuSurface(
                        shape: sel ? NeuShape.pressed : NeuShape.flat,
                        border: sel ? null : Border.all(color: Colors.transparent),
                        depth: 1,
                        padding: const EdgeInsets.symmetric(vertical: NeuTheme.s2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(sel ? items[i].selectedIcon : items[i].icon, size: 22, color: sel ? n.accent : n.textMuted),
                            const SizedBox(height: 2),
                            Text(
                              items[i].label,
                              style: context.text.labelSmall!.copyWith(color: sel ? n.accent : n.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Side navigation: a slim rail (icons + small labels) or an expanded sidebar.
class NeuSideNav extends StatelessWidget {
  const NeuSideNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.expanded = false,
    this.header,
    this.trailing,
    this.onToggleExpanded,
  });

  final List<NeuNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool expanded;
  final Widget? header;
  final Widget? trailing;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final width = expanded ? 232.0 : 88.0;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: width,
      padding: const EdgeInsets.fromLTRB(NeuTheme.s3, NeuTheme.s4, NeuTheme.s3, NeuTheme.s4),
      child: SafeArea(
        right: false,
        child: NeuSurface(
          depth: 3,
          radius: NeuTheme.radiusL,
          padding: const EdgeInsets.all(NeuTheme.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null)
                Padding(padding: const EdgeInsets.fromLTRB(NeuTheme.s2, NeuTheme.s3, NeuTheme.s2, NeuTheme.s4), child: header),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: NeuTheme.s1),
                  child: NeuPressable(
                    onTap: () => onSelected(i),
                    semanticLabel: items[i].label,
                    selected: i == selectedIndex,
                    minSize: const Size(48, 52),
                    builder: (context, s) {
                      final sel = i == selectedIndex;
                      final color = sel ? n.accent : n.textMuted;
                      final icon = Icon(sel ? items[i].selectedIcon : items[i].icon, size: 22, color: color);
                      final label = Text(
                        items[i].label,
                        style: (expanded ? context.text.labelLarge : context.text.labelSmall)!.copyWith(
                          color: sel ? n.accent : (s.hovered ? n.text : n.textMuted),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                      return NeuSurface(
                        shape: sel ? NeuShape.pressed : NeuShape.flat,
                        border: sel ? null : Border.all(color: Colors.transparent),
                        depth: 1,
                        padding: EdgeInsets.symmetric(horizontal: expanded ? NeuTheme.s4 : NeuTheme.s1, vertical: NeuTheme.s3),
                        child: expanded
                            ? Row(
                                children: [
                                  icon,
                                  const SizedBox(width: NeuTheme.s3),
                                  Expanded(child: label),
                                ],
                              )
                            : Column(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(height: 2), label]),
                      );
                    },
                  ),
                ),
              const Spacer(),
              ?trailing,
              if (onToggleExpanded != null)
                NeuPressable(
                  onTap: onToggleExpanded,
                  tooltip: expanded ? 'Collapse sidebar' : 'Expand sidebar',
                  semanticLabel: expanded ? 'Collapse sidebar' : 'Expand sidebar',
                  builder: (context, s) => Center(child: Icon(expanded ? Icons.chevron_left : Icons.chevron_right, color: n.textMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
