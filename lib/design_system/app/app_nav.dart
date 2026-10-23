import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';

import '../cupertino/cu_nav.dart';
import '../neu/neu_nav.dart';
import 'app_icons.dart';
import 'skin_scope.dart';

class AppNavItem {
  const AppNavItem({required this.label, required this.icon, AppIcon? selectedIcon}) : selectedIcon = selectedIcon ?? icon;
  final String label;
  final AppIcon icon;
  final AppIcon selectedIcon;
}

List<CuNavItem> _cuItems(List<AppNavItem> items, AppSkin skin) => [
  for (final i in items) CuNavItem(label: i.label, icon: i.icon.of(skin), selectedIcon: i.selectedIcon.of(skin)),
];

List<NeuNavItem> _neuItems(List<AppNavItem> items, AppSkin skin) => [
  for (final i in items) NeuNavItem(label: i.label, icon: i.icon.of(skin), selectedIcon: i.selectedIcon.of(skin)),
];

/// Bottom navigation for compact widths.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.items, required this.selectedIndex, required this.onSelected});

  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => NeuNavBar(items: _neuItems(items, skin), selectedIndex: selectedIndex, onSelected: onSelected),
      AppSkin.cupertino => CuTabBar(items: _cuItems(items, skin), selectedIndex: selectedIndex, onSelected: onSelected),
    };
  }
}

/// Side navigation: a rail when collapsed, a sidebar when [expanded].
class AppSideNav extends StatelessWidget {
  const AppSideNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.expanded = false,
    this.header,
    this.trailing,
    this.onToggleExpanded,
  });

  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool expanded;

  /// Builds the sidebar header. [expanded] is whether there is room for text beside the logo; the Cupertino sidebar always has.
  final Widget Function(BuildContext context, bool expanded)? header;
  final Widget? trailing;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => NeuSideNav(
        items: _neuItems(items, skin),
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        expanded: expanded,
        header: header?.call(context, expanded),
        trailing: trailing,
        onToggleExpanded: onToggleExpanded,
      ),
      AppSkin.cupertino => CuSideNav(
        items: _cuItems(items, skin),
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        header: header?.call(context, true),
        trailing: trailing,
      ),
    };
  }
}

/// Wraps the shell's content so the Cupertino sidebar can be hidden and shown from the page toolbar. [hidden] and [onToggle] are
/// ignored by the Neumorphic skin, which keeps its own rail/sidebar.
class AppSidebarScope extends StatelessWidget {
  const AppSidebarScope({super.key, required this.hidden, required this.onToggle, required this.child});

  final bool hidden;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppSkinScope.of(context) == AppSkin.cupertino ? CuSidebarScope(hidden: hidden, onToggle: onToggle, child: child) : child;
}

/// Whether navigation is a bottom bar at this width. Compact widths use one, except in the Cupertino skin on macOS,
/// which always uses a sidebar (a desktop window is never a phone).
bool appUsesBottomBar(BuildContext context, {required bool compact}) =>
    compact && !(AppSkinScope.of(context) == AppSkin.cupertino && defaultTargetPlatform == TargetPlatform.macOS);
