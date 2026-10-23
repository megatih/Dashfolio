import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/refresh_controller.dart';
import '../../design_system/app/app_ui.dart';
import 'refresh_widgets.dart';

/// Max width of page content on very wide screens.
const double kContentMaxWidth = kAppContentMaxWidth;

/// Page chrome shared by all top-level screens: the design system's page plus the app's refresh status and action.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.showRefresh = true,
    this.leading,
    this.padBody = true,
    this.scrollable = true,
    this.onRefresh,
    this.width = AppPageWidth.wide,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool showRefresh;
  final Widget? leading;
  final bool padBody;

  /// When false, [child] manages its own scrolling (e.g. a table with sticky header).
  final bool scrollable;

  /// Pull-to-refresh handler for touch devices. Defaults to a price refresh when [showRefresh] is true.
  final Future<void> Function()? onRefresh;

  /// Preferred content width (Cupertino only).
  final AppPageWidth width;

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) => AppPage(
      title: title,
      subtitle: subtitle,
      status: showRefresh ? const UpdatedChip() : null,
      actions: actions,
      refreshAction: showRefresh ? const RefreshAction() : null,
      progress: const RefreshProgressBar(),
      leading: leading,
      padBody: padBody,
      width: width,
      scrollable: scrollable,
      onRefresh: onRefresh ?? (showRefresh ? () => ref.read(refreshControllerProvider.notifier).refresh() : null),
      child: child,
    ),
  );
}

/// Titled section inside a card layout.
class SectionTitle extends AppSectionHeader {
  const SectionTitle(super.title, {super.key, super.trailing});
}
