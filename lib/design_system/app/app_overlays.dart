import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar, Tooltip, showDatePicker, showDialog, showLicensePage;
import 'package:flutter/widgets.dart';

import '../cupertino/cu_inputs.dart';
import '../cupertino/cu_overlays.dart';
import '../neu/neu_overlays.dart';
import 'app_theme.dart';
import 'skin_scope.dart';

/// Width at which sheets become centred dialogs.
const double kAppSheetDialogBreakpoint = kSheetDialogBreakpoint;

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.maxWidth = 520,
    this.scrollable = true,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => NeuDialog(title: title, actions: actions, maxWidth: maxWidth, scrollable: scrollable, child: child),
    AppSkin.cupertino => CuDialog(title: title, actions: actions, maxWidth: maxWidth, scrollable: scrollable, child: child),
  };
}

/// Shows a dialog route built by [builder] (usually an [AppDialog], possibly stateful).
Future<T?> showAppModal<T>(BuildContext context, {required WidgetBuilder builder, Color? barrierColor, bool barrierDismissible = true}) =>
    switch (AppSkinScope.of(context)) {
      AppSkin.neumorphic => showDialog<T>(
        context: context,
        builder: builder,
        barrierColor: barrierColor,
        barrierDismissible: barrierDismissible,
      ),
      AppSkin.cupertino => showCuModal<T>(context, builder: builder, barrierColor: barrierColor, barrierDismissible: barrierDismissible),
    };

Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  List<Widget> actions = const [],
  double maxWidth = 520,
}) => switch (AppSkinScope.of(context)) {
  AppSkin.neumorphic => showNeuDialog<T>(context, title: title, child: child, actions: actions, maxWidth: maxWidth),
  AppSkin.cupertino => showCuDialog<T>(context, title: title, child: child, actions: actions, maxWidth: maxWidth),
};

Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) => switch (AppSkinScope.of(context)) {
  AppSkin.neumorphic => confirmNeu(context, title: title, message: message, confirmLabel: confirmLabel, destructive: destructive),
  AppSkin.cupertino => showCuConfirm(context, title: title, message: message, confirmLabel: confirmLabel, destructive: destructive),
};

/// A form or detail sheet: a bottom sheet when compact, a centred dialog when wide.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder, double maxWidth = 560}) =>
    switch (AppSkinScope.of(context)) {
      AppSkin.neumorphic => showAdaptiveSheet<T>(context, builder: builder, maxWidth: maxWidth),
      AppSkin.cupertino => showCuSheet<T>(context, builder: builder, maxWidth: maxWidth, dialogBreakpoint: kAppSheetDialogBreakpoint),
    };

/// Date selection. Returns the picked calendar date, or null when dismissed.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  String? helpText,
}) => switch (AppSkinScope.of(context)) {
  AppSkin.neumorphic => showDatePicker(context: context, initialDate: initial, firstDate: first, lastDate: last, helpText: helpText),
  AppSkin.cupertino => showCuDatePicker(context, initial: initial, first: first, last: last, title: helpText),
};

/// The open-source licences page.
void showAppLicenses(BuildContext context, {required String applicationName, String? applicationVersion}) =>
    showLicensePage(context: context, applicationName: applicationName, applicationVersion: applicationVersion);

class AppTooltip extends StatelessWidget {
  const AppTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => Tooltip(message: message, child: child),
    AppSkin.cupertino => CuTooltip(message: message, child: child),
  };
}

/// Shows a short, auto-dismissing message. Does nothing when no host is available.
void showAppToast(BuildContext context, String message, {bool error = false}) {
  if (AppSkinScope.of(context) == AppSkin.cupertino) return showCuToast(context, message, error: error);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? context.app.loss : null, duration: const Duration(seconds: 4)),
    );
}
