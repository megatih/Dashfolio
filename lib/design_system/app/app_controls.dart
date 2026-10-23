import 'package:flutter/widgets.dart';

import '../cupertino/cu_controls.dart';
import '../neu/neu_controls.dart';
import 'app_icons.dart';
import 'skin_scope.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => NeuSwitch(value: value, onChanged: onChanged, semanticLabel: semanticLabel),
    AppSkin.cupertino => CuSwitch(value: value, onChanged: onChanged, semanticLabel: semanticLabel),
  };
}

class AppSegment<T extends Object> {
  const AppSegment(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final AppIcon? icon;
}

class AppSegmented<T extends Object> extends StatelessWidget {
  const AppSegmented({super.key, required this.segments, required this.selected, required this.onChanged, this.dense = false});

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => NeuSegmentedControl<T>(
        segments: [for (final s in segments) NeuSegment<T>(s.value, s.label, icon: s.icon?.of(skin))],
        selected: selected,
        onChanged: onChanged,
        dense: dense,
      ),
      AppSkin.cupertino => CuSegmented<T>(
        segments: [for (final s in segments) CuSegment<T>(s.value, s.label, icon: s.icon?.of(skin))],
        selected: selected,
        onChanged: onChanged,
        dense: dense,
      ),
    };
  }
}

class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.selected = false, this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final AppIcon? icon;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => NeuChip(label: label, selected: selected, onTap: onTap, icon: icon?.of(skin)),
      AppSkin.cupertino => CuChip(label: label, selected: selected, onTap: onTap, icon: icon?.of(skin)),
    };
  }
}

/// Linear progress; indeterminate when [value] is null.
class AppProgress extends StatelessWidget {
  const AppProgress({super.key, this.value, this.height = 10});

  final double? value;
  final double height;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => NeuProgress(value: value, height: height),
    AppSkin.cupertino => CuProgress(value: value),
  };
}
