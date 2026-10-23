import 'package:flutter/material.dart' show RefreshIndicator, Scaffold;
import 'package:flutter/widgets.dart';

import '../cupertino/cu_nav.dart';
import 'app_theme.dart';
import 'skin_scope.dart';

/// Max width of page content on very wide screens.
const double kAppContentMaxWidth = 1360;

const double _compactBelow = 600;

/// How wide page content may grow. Neumorphic always uses [kAppContentMaxWidth]; Cupertino keeps forms to a readable column.
enum AppPageWidth { wide, readable }

/// A full-screen page background with an optional bottom bar.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.body, this.bottomBar});

  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => Scaffold(body: body, bottomNavigationBar: bottomBar),
    AppSkin.cupertino => CuScaffold(body: body, bottomBar: bottomBar),
  };
}

/// Page chrome shared by all top-level screens: title row, actions, status line, centered content.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.status,
    this.actions = const [],
    this.refreshAction,
    this.progress,
    this.leading,
    this.padBody = true,
    this.scrollable = true,
    this.onRefresh,
    this.width = AppPageWidth.wide,
  });

  final String title;
  final Widget child;

  /// Plain text under the title; ignored when [status] is set.
  final String? subtitle;

  /// A status widget under the title (for example "Updated 2 min ago").
  final Widget? status;
  final List<Widget> actions;

  /// A trailing action rendered after [actions] (the refresh button).
  final Widget? refreshAction;

  /// A thin progress strip under the header.
  final Widget? progress;
  final Widget? leading;
  final bool padBody;

  /// When false, [child] manages its own scrolling (e.g. a table with sticky header).
  final bool scrollable;

  /// Pull-to-refresh handler for touch devices.
  final Future<void> Function()? onRefresh;

  /// Preferred content width (Cupertino only).
  final AppPageWidth width;

  @override
  Widget build(BuildContext context) {
    if (AppSkinScope.of(context) == AppSkin.cupertino) {
      return CuPage(
        title: title,
        contentMaxWidth: width == AppPageWidth.readable ? 720 : kAppContentMaxWidth,
        compactBelow: _compactBelow,
        subtitle: subtitle,
        status: status,
        actions: actions,
        refreshAction: refreshAction,
        progress: progress,
        leading: leading,
        padBody: padBody,
        scrollable: scrollable,
        onRefresh: onRefresh,
        child: child,
      );
    }
    final compact = MediaQuery.sizeOf(context).width < _compactBelow;
    final gutter = compact ? AppSpace.s4 : AppSpace.s6;
    final header = Padding(
      padding: EdgeInsets.fromLTRB(gutter, AppSpace.s4, gutter, AppSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.text.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (status != null)
                  Padding(padding: const EdgeInsets.only(top: 2), child: status)
                else if (subtitle != null)
                  Text(subtitle!, style: context.text.bodySmall),
              ],
            ),
          ),
          for (final a in actions)
            Padding(
              padding: const EdgeInsets.only(left: AppSpace.s2),
              child: a,
            ),
          if (refreshAction != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpace.s2),
              child: refreshAction,
            ),
        ],
      ),
    );

    Widget body = child;
    if (padBody) body = Padding(padding: EdgeInsets.fromLTRB(gutter, AppSpace.s2, gutter, AppSpace.s6), child: body);
    body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kAppContentMaxWidth),
        child: body,
      ),
    );
    if (scrollable) {
      body = SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: body);
      if (onRefresh != null) body = RefreshIndicator(onRefresh: onRefresh!, child: body);
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kAppContentMaxWidth),
              child: header,
            ),
          ),
          if (progress != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Center(
                child: SizedBox(width: kAppContentMaxWidth, child: progress),
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Titled section header with an optional trailing widget.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(title, style: context.text.titleMedium)),
        ),
        ?trailing,
      ],
    ),
    AppSkin.cupertino => CuSectionHeader(title, trailing: trailing),
  };
}
