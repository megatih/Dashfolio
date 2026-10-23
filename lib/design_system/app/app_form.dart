import 'package:flutter/widgets.dart';

import '../cupertino/cu_overlays.dart';
import '../cupertino/cu_section.dart';
import 'app_button.dart';
import 'app_icons.dart';
import 'app_surface.dart';
import 'app_theme.dart';
import 'skin_scope.dart';

/// A group of related content. Neumorphic: a card with a heading. Cupertino: an inset-grouped section whose rows are
/// separated by hairlines (header above, [footer] below). [AppButtonGroup]s become action rows.
///
/// With [bare] the Neumorphic render has no card (a muted label, children spaced evenly): for forms inside a sheet.
class AppSection extends StatelessWidget {
  const AppSection({super.key, required this.children, this.title, this.footer, this.trailing, this.bare = false});

  final String? title;
  final String? footer;
  final Widget? trailing;
  final List<Widget> children;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    if (AppSkinScope.of(context) == AppSkin.cupertino) {
      final skin = AppSkin.cupertino;
      final rows = <Widget>[
        for (final c in children.map((c) => c is AppSectionItem ? c.child : c).where((c) => c is! AppGap))
          if (c is AppButtonGroup)
            for (final b in c.buttons)
              CuActionRow(
                label: b.label,
                icon: b.icon?.of(skin),
                onTap: b.onPressed,
                destructive: b.kind == AppButtonKind.danger,
                loading: b.loading,
              )
          else
            c,
      ];
      final section = CuSection(title: title, footer: footer, trailing: trailing, children: rows);
      return bare
          ? section
          : Padding(
              padding: const EdgeInsets.only(bottom: CuSectionGap.value),
              child: section,
            );
    }
    final footerText = footer == null ? null : Text(footer!, style: context.text.bodySmall);
    if (bare) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s2),
              child: Text(title!, style: context.text.labelMedium!.copyWith(color: context.app.textMuted)),
            ),
          for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: AppSpace.s4), c],
          if (footerText != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s2),
              child: footerText,
            ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s5),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              if (trailing == null)
                Semantics(header: true, child: Text(title!, style: context.text.titleMedium))
              else
                Row(
                  children: [
                    Expanded(
                      child: Semantics(header: true, child: Text(title!, style: context.text.titleMedium)),
                    ),
                    trailing!,
                  ],
                ),
              const SizedBox(height: AppSpace.s4),
            ],
            ...children,
            if (footerText != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s2),
                child: footerText,
              ),
          ],
        ),
      ),
    );
  }
}

/// Vertical space between children of a Neumorphic [AppSection]; the Cupertino skin spaces rows itself and drops it.
class AppGap extends StatelessWidget {
  const AppGap(this.height, {super.key});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

/// A child of an [AppSection] with extra space above it in Neumorphic (ignored by Cupertino, which pads rows itself).
class AppSectionItem extends StatelessWidget {
  const AppSectionItem({super.key, this.top = 0, required this.child});

  final double top;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: child,
  );
}

/// Vertical gap between page-level Cupertino sections (the Neumorphic skin uses [AppSpace.s5]).
abstract final class CuSectionGap {
  static const double value = 24;
}

/// A label (and optional description) with a control on the trailing side. Narrow widths stack the control under the label
/// (always in Neumorphic; in Cupertino only when [wide] is set, for controls such as segmented controls).
class AppFormRow extends StatelessWidget {
  const AppFormRow({super.key, required this.label, required this.control, this.description, this.wide = false});

  final String label;
  final String? description;
  final Widget control;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (AppSkinScope.of(context) == AppSkin.cupertino) {
      return CuFormRow(label: label, description: description, control: control, wide: wide);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s4),
      child: LayoutBuilder(
        builder: (context, c) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.titleSmall),
              if (description != null) Text(description!, style: context.text.bodySmall),
            ],
          );
          if (c.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: AppSpace.s2),
                control,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: AppSpace.s4),
              control,
            ],
          );
        },
      ),
    );
  }
}

/// A custom control with a label: above it in Neumorphic, in a row beside it inside a Cupertino section. [errorText] shows below.
class AppField extends StatelessWidget {
  const AppField({super.key, required this.label, required this.child, this.errorText});

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    if (AppSkinScope.of(context) == AppSkin.cupertino) {
      return CuField(label: label, errorText: errorText, child: child);
    }
    final n = context.app;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s2, left: 2),
          child: Text(label, style: context.text.labelMedium!.copyWith(color: n.textMuted)),
        ),
        child,
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s1, left: 2),
            child: Text(errorText!, style: context.text.bodySmall!.copyWith(color: n.loss)),
          ),
      ],
    );
  }
}

/// Buttons laid out together: a wrapping row in Neumorphic and outside a section; one action row each inside a Cupertino
/// [AppSection].
class AppButtonGroup extends StatelessWidget {
  const AppButtonGroup({super.key, required this.buttons});

  final List<AppButton> buttons;

  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpace.s3, runSpacing: AppSpace.s3, children: buttons);
}

/// The frame of a form sheet. Neumorphic: a title row with a close button, the [children] spaced evenly, then a full-width
/// confirm button (with an optional destructive button beside it). Cupertino: a sheet bar with Cancel, the title and a bold
/// confirm action above grouped [children], with the destructive action as a red row below.
class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.confirmLabel,
    required this.onConfirm,
    this.busy = false,
    this.closeResult,
    this.destructiveLabel,
    this.onDestructive,
    this.footer,
    this.actionsGap = AppSpace.s6,
    this.shortConfirmLabel,
  });

  final String title;
  final List<Widget> children;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final bool busy;

  /// What closing the sheet without confirming returns to the caller.
  final Object? closeResult;
  final String? destructiveLabel;
  final VoidCallback? onDestructive;

  /// A note under the form (for example "Please fix the highlighted fields").
  final String? footer;

  /// Neumorphic spacing between the last child and the buttons.
  final double actionsGap;

  /// A one-word label for the Cupertino sheet bar ("Add", "Save"); defaults to [confirmLabel].
  final String? shortConfirmLabel;

  @override
  Widget build(BuildContext context) {
    if (AppSkinScope.of(context) == AppSkin.cupertino) {
      final n = context.app;
      return CuSheetScaffold(
        title: title,
        onCancel: () => Navigator.of(context).pop(closeResult),
        confirmLabel: shortConfirmLabel ?? confirmLabel,
        onConfirm: busy ? null : onConfirm,
        busy: busy,
        destructiveLabel: destructiveLabel,
        onDestructive: busy ? null : onDestructive,
        footer: footer == null
            ? null
            : Text(
                footer!,
                textAlign: TextAlign.center,
                style: context.text.bodySmall!.copyWith(color: n.loss),
              ),
        children: children,
      );
    }
    final n = context.app;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(title, style: context.text.titleLarge)),
              ),
              AppIconButton(icon: AppIcon.close, tooltip: 'Close', size: 40, onPressed: () => Navigator.of(context).pop(closeResult)),
            ],
          ),
          const SizedBox(height: AppSpace.s5),
          for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: AppSpace.s4), c],
          SizedBox(height: actionsGap),
          Row(
            children: [
              if (destructiveLabel != null) ...[
                AppButton(
                  label: destructiveLabel!,
                  kind: AppButtonKind.danger,
                  icon: AppIcon.delete,
                  onPressed: busy ? null : onDestructive,
                ),
                const SizedBox(width: AppSpace.s3),
              ],
              Expanded(
                child: AppButton(label: confirmLabel, kind: AppButtonKind.primary, expand: true, loading: busy, onPressed: onConfirm),
              ),
            ],
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s3),
              child: Text(
                footer!,
                textAlign: TextAlign.center,
                style: context.text.bodySmall!.copyWith(color: n.loss),
              ),
            ),
        ],
      ),
    );
  }
}
