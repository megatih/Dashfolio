import 'package:flutter/material.dart' show AutovalidateMode, DropdownMenuItem, FormFieldValidator;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../cupertino/cu_inputs.dart';
import '../neu/neu_inputs.dart';
import 'app_icons.dart';
import 'skin_scope.dart';

/// A text input with an optional label above it and an error line below.
class AppTextField extends StatelessWidget {
  const AppTextField({
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
  final AppIcon? prefixIcon;
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

  /// Credentials and PINs: no suggestions, autocorrect or personalised learning, and never echoed.
  final bool sensitive;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    final icon = prefixIcon?.of(skin);
    return switch (skin) {
      AppSkin.neumorphic => NeuTextField(
        controller: controller,
        label: label,
        hint: hint,
        errorText: errorText,
        prefixIcon: icon,
        suffix: suffix,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        validator: validator,
        obscureText: obscureText,
        autofocus: autofocus,
        maxLines: maxLines,
        focusNode: focusNode,
        textInputAction: textInputAction,
        enabled: enabled,
        textAlign: textAlign,
        maxLength: maxLength,
        initialValue: initialValue,
        autovalidateMode: autovalidateMode,
        sensitive: sensitive,
      ),
      AppSkin.cupertino => CuTextField(
        controller: controller,
        label: label,
        hint: hint,
        errorText: errorText,
        prefixIcon: icon,
        suffix: suffix,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        validator: validator,
        obscureText: obscureText,
        autofocus: autofocus,
        maxLines: maxLines,
        focusNode: focusNode,
        textInputAction: textInputAction,
        enabled: enabled,
        textAlign: textAlign,
        maxLength: maxLength,
        initialValue: initialValue,
        autovalidateMode: autovalidateMode,
        sensitive: sensitive,
      ),
    };
  }
}

/// One choice in an [AppSelect].
class AppOption<T> {
  const AppOption(this.value, this.label);
  final T value;
  final String label;
}

/// Pick one value from a list.
class AppSelect<T> extends StatelessWidget {
  const AppSelect({super.key, required this.value, required this.options, required this.onChanged, this.label, this.hint, this.width});

  final T? value;
  final List<AppOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;

  /// Fixed width in Neumorphic (Cupertino sizes the control to its value).
  final double? width;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => _fixed(
      NeuDropdown<T>(
        value: value,
        items: [for (final o in options) DropdownMenuItem<T>(value: o.value, child: Text(o.label))],
        onChanged: onChanged,
        label: label,
        hint: hint,
      ),
    ),
    AppSkin.cupertino => CuSelect<T>(
      value: value,
      options: [for (final o in options) CuOption<T>(o.value, o.label)],
      onChanged: onChanged,
      label: label,
      hint: hint,
    ),
  };

  Widget _fixed(Widget w) => width == null ? w : SizedBox(width: width, child: w);
}
