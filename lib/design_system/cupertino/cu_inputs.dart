import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'cu_menu.dart';
import 'cu_section.dart';
import 'cu_surface.dart';
import 'cupertino_theme.dart';

class CuTextField extends StatefulWidget {
  const CuTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.focusNode,
    this.textInputAction,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.initialValue,
    this.autovalidateMode,
    this.sensitive = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final bool autofocus;
  final int maxLines;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool enabled;
  final TextAlign textAlign;
  final int? maxLength;
  final String? initialValue;
  final AutovalidateMode? autovalidateMode;
  final bool sensitive;

  @override
  State<CuTextField> createState() => _CuTextFieldState();
}

class _CuTextFieldState extends State<CuTextField> {
  TextEditingController? _own;

  TextEditingController get _controller => widget.controller ?? (_own ??= TextEditingController(text: widget.initialValue));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final inSection = CuSectionScope.of(context);
    return FormField<String>(
      initialValue: widget.controller?.text ?? widget.initialValue ?? '',
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        final error = widget.errorText ?? state.errorText;
        final field = CupertinoTextField(
          controller: _controller,
          focusNode: widget.focusNode,
          placeholder: widget.hint,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          obscureText: widget.obscureText || widget.sensitive,
          smartDashesType: widget.sensitive ? SmartDashesType.disabled : null,
          smartQuotesType: widget.sensitive ? SmartQuotesType.disabled : null,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          textInputAction: widget.textInputAction,
          textAlign: inSection && widget.label != null && widget.textAlign == TextAlign.start ? TextAlign.end : widget.textAlign,
          autocorrect: !widget.sensitive,
          enableSuggestions: !widget.sensitive,
          enableIMEPersonalizedLearning: !widget.sensitive,
          onChanged: (v) {
            state.didChange(v);
            widget.onChanged?.call(v);
          },
          onSubmitted: widget.onSubmitted,
          style: t.body,
          placeholderStyle: t.body.copyWith(color: p.tertiaryLabel),
          padding: inSection
              ? EdgeInsets.symmetric(vertical: m.pointer ? 2 : 4)
              : EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: (m.pointer ? m.largeControlHeight : m.rowHeight) / 2 - (t.body.fontSize ?? 17) * 0.65,
                ),
          prefix: widget.prefixIcon == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(left: inSection ? 0 : 10, right: inSection ? 8 : 0),
                  child: Icon(widget.prefixIcon, size: m.iconSize, color: p.secondaryLabel),
                ),
          suffix: widget.suffix == null ? null : Padding(padding: const EdgeInsets.only(right: 8), child: widget.suffix),
          decoration: inSection
              ? const BoxDecoration()
              : BoxDecoration(
                  color: p.fill,
                  borderRadius: BorderRadius.circular(m.groupRadius),
                  border: error != null ? Border.all(color: p.loss, width: 1.5) : null,
                ),
        );
        final errorText = error == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Semantics(
                  liveRegion: true,
                  child: Text(error, style: t.footnote.copyWith(color: p.loss)),
                ),
              );
        if (inSection) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label != null)
                Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(widget.label!, style: t.body),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: field),
                  ],
                )
              else
                field,
              ?errorText,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Text(widget.label!, style: t.footnote.copyWith(fontWeight: FontWeight.w500)),
              ),
            field,
            ?errorText,
          ],
        );
      },
    );
  }
}

class CuOption<T> {
  const CuOption(this.value, this.label);
  final T value;
  final String label;
}

/// Pick one value. A pop-up button opens a pull-down menu anchored to it; on touch devices a long list (currencies) opens a
/// wheel picker instead.
class CuSelect<T> extends StatelessWidget {
  const CuSelect({super.key, required this.value, required this.options, required this.onChanged, this.label, this.hint});

  final T? value;
  final List<CuOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;

  bool get _wheel => options.length > 12 && !CupertinoMetrics.current.pointer;

  Future<void> _openWheel(BuildContext context) async {
    var index = options.indexWhere((o) => o.value == value);
    if (index < 0) index = 0;
    final controller = FixedExtentScrollController(initialItem: index);
    final picked = await showCupertinoModalPopup<CuOption<T>>(
      context: context,
      builder: (ctx) {
        final p = CupertinoPalette.of(ctx);
        final t = CupertinoTypography.of(ctx);
        return Container(
          height: 300,
          color: p.secondaryGroupedBackground,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel', style: t.body.copyWith(color: p.accent)),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(options[index]),
                      child: Text('Done', style: t.headline.copyWith(color: p.accent)),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: controller,
                    itemExtent: 36,
                    onSelectedItemChanged: (i) => index = i,
                    children: [
                      for (final o in options)
                        Center(
                          child: Text(o.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.body),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
    if (picked != null) onChanged?.call(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final inSection = CuSectionScope.of(context);
    final selected = options.where((o) => o.value == value).firstOrNull;
    final text = selected?.label ?? hint ?? '';
    final enabled = onChanged != null;

    Widget face(VoidCallback open) {
      final valueText = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.body.copyWith(color: selected == null ? p.tertiaryLabel : (inSection ? p.secondaryLabel : p.label)),
      );
      final chevrons = Icon(CupertinoIcons.chevron_up_chevron_down, size: m.iconSize - 4, color: p.secondaryLabel);
      final box = inSection
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(child: valueText),
                const SizedBox(width: 6),
                chevrons,
              ],
            )
          : Container(
              constraints: BoxConstraints(minHeight: m.pointer ? m.largeControlHeight : m.rowHeight),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: p.fill, borderRadius: BorderRadius.circular(m.groupRadius)),
              child: Row(
                children: [
                  Expanded(child: valueText),
                  chevrons,
                ],
              ),
            );
      return Semantics(
        button: true,
        enabled: enabled,
        label: label,
        value: text,
        excludeSemantics: true,
        onTap: enabled ? open : null,
        child: CuTappable(
          onTap: enabled ? open : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: m.pointer ? 24 : m.minHit - 8),
            child: Align(alignment: inSection ? Alignment.centerRight : Alignment.center, widthFactor: inSection ? 1 : null, child: box),
          ),
        ),
      );
    }

    final Widget control = _wheel
        ? Builder(builder: (context) => face(() => _openWheel(context)))
        : CuPopupMenu<T>(
            items: [for (final o in options) CuMenuItem<T>(o.value, o.label, checked: o.value == value)],
            onSelected: (v) => onChanged?.call(v),
            enabled: enabled,
            builder: (context, open) => face(open),
          );
    if (inSection) {
      if (label == null) return control;
      return Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(label!, style: t.body),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: control),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Text(label!, style: t.footnote.copyWith(fontWeight: FontWeight.w500)),
          ),
        control,
      ],
    );
  }
}

/// A date picker in a popup. Returns null when cancelled.
Future<DateTime?> showCuDatePicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  String? title,
}) {
  var picked = initial;
  Widget content(BuildContext ctx) {
    final p = CupertinoPalette.of(ctx);
    final t = CupertinoTypography.of(ctx);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CupertinoButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: t.body.copyWith(color: p.accent)),
            ),
            if (title != null)
              Flexible(
                child: Text(title, style: t.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            CupertinoButton(
              onPressed: () => Navigator.of(ctx).pop(picked),
              child: Text('Done', style: t.headline.copyWith(color: p.accent)),
            ),
          ],
        ),
        SizedBox(
          height: 216,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: initial,
            minimumDate: first,
            maximumDate: last,
            onDateTimeChanged: (d) => picked = d,
          ),
        ),
      ],
    );
  }

  if (CupertinoMetrics.current.pointer) {
    return showCupertinoDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: CupertinoPopupSurface(child: content(ctx)),
        ),
      ),
    );
  }
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => Container(
      color: CupertinoPalette.of(ctx).secondaryGroupedBackground,
      child: SafeArea(top: false, child: content(ctx)),
    ),
  );
}
