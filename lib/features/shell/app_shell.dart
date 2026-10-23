import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/refresh_controller.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/repositories/settings_repository.dart';
import '../common/breakpoints.dart';
import '../transactions/transaction_form.dart';
import 'search_palette.dart';

const _items = [
  AppNavItem(label: 'Dashboard', icon: AppIcon.dashboard, selectedIcon: AppIcon.dashboardFilled),
  AppNavItem(label: 'Portfolios', icon: AppIcon.folder, selectedIcon: AppIcon.folderFilled),
  AppNavItem(label: 'Markets', icon: AppIcon.showChart, selectedIcon: AppIcon.candlestickChartFilled),
  AppNavItem(label: 'Income', icon: AppIcon.savings, selectedIcon: AppIcon.savingsFilled),
  AppNavItem(label: 'Settings', icon: AppIcon.settings, selectedIcon: AppIcon.settingsFilled),
];

/// Adaptive navigation shell: bottom bar (compact), rail (medium), sidebar (expanded).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Refresh once on launch if the data is stale and there is something to refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasHoldings =
          (ref.read(transactionsProvider).value ?? const []).isNotEmpty || (ref.read(watchlistsProvider).value ?? const []).isNotEmpty;
      if (hasHoldings) ref.read(refreshControllerProvider.notifier).refreshIfStale();
    });
  }

  void _goTo(int index) => widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);

  Map<ShortcutActivator, VoidCallback> _bindings() {
    Map<ShortcutActivator, VoidCallback> both(LogicalKeyboardKey key, VoidCallback cb) => {
      SingleActivator(key, control: true): cb,
      SingleActivator(key, meta: true): cb,
    };
    final digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
    ];
    return {
      ...both(LogicalKeyboardKey.keyR, () => ref.read(refreshControllerProvider.notifier).refresh()),
      ...both(LogicalKeyboardKey.keyK, () => showSearchPalette(context)),
      ...both(LogicalKeyboardKey.keyN, () => showTransactionForm(context, portfolioId: ref.read(selectedPortfolioProvider))),
      for (var i = 0; i < digits.length; i++) ...both(digits[i], () => _goTo(i)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = ScreenSize.of(context);
    final index = widget.navigationShell.currentIndex;
    final collapsed = ref.watch(appSettingsProvider.select((s) => s.sidebarCollapsed));
    final n = context.app;

    final body = AppSurfaceScope(reduced: false, child: widget.navigationShell);

    Widget scaffold;
    if (appUsesBottomBar(context, compact: size.isCompact)) {
      scaffold = AppScaffold(
        body: body,
        bottomBar: AppTabBar(items: _items, selectedIndex: index, onSelected: _goTo),
      );
    } else {
      final expanded = size.isExpanded && !collapsed;
      scaffold = AppScaffold(
        body: AppSidebarScope(
          hidden: collapsed,
          onToggle: () => ref.read(settingsRepositoryProvider).set(SettingKeys.sidebarCollapsed, '${!collapsed}'),
          child: Row(
            children: [
              AppSideNav(
                items: _items,
                selectedIndex: index,
                onSelected: _goTo,
                expanded: expanded,
                header: (context, wide) => Row(
                  mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    AppIconView(AppIcon.pieChartFilled, color: n.accent),
                    if (wide) ...[
                      const SizedBox(width: AppSpace.s3),
                      Flexible(
                        child: Text('Dashfolio', style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
                onToggleExpanded: size.isExpanded
                    ? () => ref.read(settingsRepositoryProvider).set(SettingKeys.sidebarCollapsed, '${!collapsed}')
                    : null,
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: _bindings(),
      child: Focus(autofocus: true, child: scaffold),
    );
  }
}
