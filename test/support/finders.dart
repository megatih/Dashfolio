import 'package:dashfolio/design_system/app/app_icons.dart';
import 'package:dashfolio/design_system/cupertino/cu_overlays.dart';
import 'package:flutter/cupertino.dart' show CupertinoAlertDialog, CupertinoPopupSurface;
import 'package:flutter/material.dart' show Dialog, Icon, Tooltip;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds an icon action by the label every skin gives it: the Neumorphic skin shows it as a tooltip, the Cupertino
/// skin only exposes it to assistive technology. A sheet's "Close" is "Cancel" in the Cupertino skin, as on Apple platforms.
Finder byAction(String label) {
  final cupertinoLabel = label == 'Close' ? 'Cancel' : label;
  return find.byWidgetPredicate(
    (w) =>
        (w is Tooltip && w.message == label) ||
        (w is Semantics && w.properties.button == true && (w.properties.label == label || w.properties.label == cupertinoLabel)),
    description: 'action "$label"',
  );
}

/// A dialog of either skin.
Finder anyDialog() => find.byWidgetPredicate(
  (w) => w is Dialog || w is CuDialog || w is CupertinoPopupSurface || w is CupertinoAlertDialog,
  description: 'a dialog',
);

/// An [AppIcon] in either skin's glyph.
Finder byAppIcon(AppIcon icon) =>
    find.byWidgetPredicate((w) => w is Icon && (w.icon == icon.material || w.icon == icon.cupertino), description: 'icon ${icon.name}');

/// A sheet's confirm button by its full label; the Cupertino sheet bar shows a one-word form ("Add", "Save", "Create").
Finder byConfirm(String label) {
  const short = {'Create portfolio': 'Create', 'Add transaction': 'Add', 'Save changes': 'Save'};
  return find.byWidgetPredicate((w) => w is Text && (w.data == label || w.data == short[label]), description: 'confirm "$label"');
}
