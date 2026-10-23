import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'neu_surface.dart';
import 'tokens.dart';

/// Inset text field with an optional label above and error below.
class NeuTextField extends StatefulWidget {
  const NeuTextField({
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

  /// For secrets (API keys, PINs): hides the text and switches off autocorrect, suggestions, personalised keyboard
  /// learning and smart punctuation, so nothing typed here is remembered by the keyboard or substituted.
  final bool sensitive;

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _hasFocus = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final tt = context.text;
    return FormField<String>(
      initialValue: widget.controller?.text ?? widget.initialValue ?? '',
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        final error = widget.errorText ?? state.errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: NeuTheme.s2, left: 2),
                child: Text(widget.label!, style: tt.labelMedium!.copyWith(color: n.textMuted)),
              ),
            NeuSurface(
              shape: NeuShape.concave,
              depth: 2,
              radius: NeuTheme.radiusM,
              border: Border.all(color: error != null ? n.loss : (_hasFocus ? n.accent : Colors.transparent), width: 1.5),
              constraints: const BoxConstraints(minHeight: NeuTheme.minHit),
              padding: const EdgeInsets.symmetric(horizontal: NeuTheme.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(widget.prefixIcon, size: 18, color: n.textMuted),
                    const SizedBox(width: NeuTheme.s2),
                  ],
                  Expanded(
                    child: TextField(
                      controller:
                          widget.controller ?? (widget.initialValue != null ? TextEditingController(text: widget.initialValue) : null),
                      focusNode: _focus,
                      enabled: widget.enabled,
                      autofocus: widget.autofocus,
                      obscureText: widget.obscureText || widget.sensitive,
                      autocorrect: !widget.sensitive,
                      enableSuggestions: !widget.sensitive,
                      enableIMEPersonalizedLearning: !widget.sensitive,
                      smartDashesType: widget.sensitive ? SmartDashesType.disabled : null,
                      smartQuotesType: widget.sensitive ? SmartQuotesType.disabled : null,
                      autofillHints: null,
                      maxLines: widget.maxLines,
                      maxLength: widget.maxLength,
                      textAlign: widget.textAlign,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      inputFormatters: widget.inputFormatters,
                      style: tt.bodyLarge,
                      cursorColor: n.accent,
                      onChanged: (v) {
                        state.didChange(v);
                        widget.onChanged?.call(v);
                      },
                      onSubmitted: widget.onSubmitted,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: tt.bodyLarge!.copyWith(color: n.textMuted.withValues(alpha: 0.8)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        isDense: true,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(vertical: NeuTheme.s3),
                      ),
                    ),
                  ),
                  if (widget.suffix != null) widget.suffix!,
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: NeuTheme.s1, left: 2),
                child: Semantics(
                  liveRegion: true,
                  child: Text(error, style: tt.bodySmall!.copyWith(color: n.loss)),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Dropdown inside an inset well.
class NeuDropdown<T> extends StatelessWidget {
  const NeuDropdown({super.key, required this.value, required this.items, required this.onChanged, this.label, this.hint});

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final tt = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: NeuTheme.s2, left: 2),
            child: Text(label!, style: tt.labelMedium!.copyWith(color: n.textMuted)),
          ),
        NeuSurface(
          shape: NeuShape.concave,
          depth: 2,
          radius: NeuTheme.radiusM,
          padding: const EdgeInsets.symmetric(horizontal: NeuTheme.s3),
          constraints: const BoxConstraints(minHeight: NeuTheme.minHit),
          alignment: Alignment.centerLeft,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              hint: hint == null ? null : Text(hint!, style: tt.bodyLarge!.copyWith(color: n.textMuted)),
              dropdownColor: n.surface,
              borderRadius: BorderRadius.circular(NeuTheme.radiusM),
              style: tt.bodyLarge,
              iconEnabledColor: n.textMuted,
              menuMaxHeight: 360,
            ),
          ),
        ),
      ],
    );
  }
}
