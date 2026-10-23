import 'package:flutter/material.dart';

import 'neu_surface.dart';
import 'tokens.dart';

/// Width at/above which sheets are presented as centered dialogs.
const double kSheetDialogBreakpoint = 600;

/// A neumorphic dialog container.
class NeuDialog extends StatelessWidget {
  const NeuDialog({
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
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: context.text.titleLarge)),
        const SizedBox(height: NeuTheme.s4),
        if (scrollable) Flexible(child: SingleChildScrollView(child: child)) else child,
        if (actions.isNotEmpty) ...[
          const SizedBox(height: NeuTheme.s5),
          Wrap(alignment: WrapAlignment.end, spacing: NeuTheme.s3, runSpacing: NeuTheme.s3, children: actions),
        ],
      ],
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(NeuTheme.s4),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: NeuSurface(depth: 4, radius: NeuTheme.radiusL, padding: const EdgeInsets.all(NeuTheme.s6), child: body),
      ),
    );
  }
}

Future<T?> showNeuDialog<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  List<Widget> actions = const [],
  double maxWidth = 520,
}) => showDialog<T>(
  context: context,
  builder: (_) => NeuDialog(title: title, actions: actions, maxWidth: maxWidth, child: child),
);

/// Confirmation helper; returns true when confirmed.
Future<bool> confirmNeu(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => NeuDialog(
      title: title,
      actions: [
        _DialogButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx, false)),
        _DialogButton(label: confirmLabel, primary: !destructive, danger: destructive, onPressed: () => Navigator.pop(ctx, true)),
      ],
      child: Text(message, style: ctx.text.bodyMedium),
    ),
  );
  return result ?? false;
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.label, required this.onPressed, this.primary = false, this.danger = false});
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    return NeuPressable(
      onTap: onPressed,
      semanticLabel: label,
      builder: (context, s) => NeuSurface(
        shape: s.pressed ? NeuShape.pressed : NeuShape.convex,
        depth: 2,
        color: danger ? n.loss : (primary ? n.accent : null),
        padding: const EdgeInsets.symmetric(horizontal: NeuTheme.s5, vertical: NeuTheme.s2),
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.text.labelLarge!.copyWith(
            color: danger ? (n.isDark ? const Color(0xFF2A0A0A) : Colors.white) : (primary ? n.onAccent : n.text),
          ),
        ),
      ),
    );
  }
}

/// Presents [builder] as a bottom sheet on compact widths and a dialog on wide ones.
Future<T?> showAdaptiveSheet<T>(BuildContext context, {required WidgetBuilder builder, double maxWidth = 560}) {
  final wide = MediaQuery.sizeOf(context).width >= kSheetDialogBreakpoint;
  if (wide) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(NeuTheme.s6),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
          child: NeuSurface(
            depth: 4,
            radius: NeuTheme.radiusL,
            child: ClipRRect(borderRadius: BorderRadius.circular(NeuTheme.radiusL), child: builder(ctx)),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(top: NeuTheme.s6, bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: NeuSurface(
        depth: 4,
        radius: NeuTheme.radiusL,
        child: ClipRRect(borderRadius: BorderRadius.circular(NeuTheme.radiusL), child: builder(ctx)),
      ),
    ),
  );
}

/// Tooltip with the app's styling.
class NeuTooltip extends StatelessWidget {
  const NeuTooltip({super.key, required this.message, required this.child});
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(message: message, child: child);
}
