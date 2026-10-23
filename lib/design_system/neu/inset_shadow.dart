import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints inner (inset) shadows inside a rounded rectangle.
///
/// Flutter's [BoxShadow] only supports outer shadows, so the inset effect is
/// produced by blurring the area *outside* the shape (offset by the shadow
/// offset) and clipping the result to the shape.
class InsetShadowPainter extends CustomPainter {
  const InsetShadowPainter({required this.radius, required this.shadows});

  final BorderRadius radius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty || size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);
    canvas
      ..save()
      ..clipRRect(rrect);
    for (final s in shadows) {
      final reach = s.blurRadius * 2 + math.max(s.offset.dx.abs(), s.offset.dy.abs()) + 8;
      final outer = Path()..addRect(rect.inflate(reach));
      final inner = Path()..addRRect(rrect.shift(s.offset));
      final hole = Path.combine(PathOperation.difference, outer, inner);
      canvas.drawPath(
        hole,
        Paint()
          ..color = s.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(InsetShadowPainter old) => old.radius != radius || old.shadows != shadows;
}
