// Renders the Dashfolio app icon with Flutter's canvas.
//
//   flutter test tool/icon_generator_test.dart
//
// Writes assets/icon/app_icon.png (rounded tile on transparent background) and
// assets/icon/app_icon_ios.png (full-bleed, no transparency). Then run
// `dart run flutter_launcher_icons` to produce the per-platform icon sets.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dashfolio/design_system/neu/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;

class _Donut extends CustomPainter {
  const _Donut(this.n);
  final NeuTheme n;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.width * 0.27;
    final stroke = size.width * 0.115;
    final rect = Rect.fromCircle(center: c, radius: radius);
    final segments = [(const Color(0xFF2557D6), 0.46), (const Color(0xFF12A05A), 0.30), (const Color(0xFFE59A1E), 0.24)];
    const gap = 0.05;
    var start = -math.pi / 2 + 0.2;
    for (final (color, share) in segments) {
      final sweep = share * 2 * math.pi - gap;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      start += share * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_Donut old) => false;
}

Widget _icon({required bool fullBleed}) {
  const n = NeuTheme.light;
  final tileSize = fullBleed ? _size : _size * 0.84;
  final radius = tileSize * 0.225;
  final tile = Container(
    width: tileSize,
    height: tileSize,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(fullBleed ? 0 : radius),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF1F5FA), Color(0xFFD9E0EA)]),
      boxShadow: fullBleed
          ? null
          : [
              BoxShadow(color: n.highlight, offset: const Offset(-18, -18), blurRadius: 40),
              BoxShadow(color: n.shadow.withValues(alpha: 0.75), offset: const Offset(20, 20), blurRadius: 44),
            ],
    ),
    child: Center(
      child: Container(
        width: tileSize * 0.64,
        height: tileSize * 0.64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD3DBE6), Color(0xFFF4F7FB)],
          ),
          boxShadow: [
            BoxShadow(color: n.shadow.withValues(alpha: 0.55), offset: const Offset(10, 10), blurRadius: 22),
            BoxShadow(color: n.highlight, offset: const Offset(-10, -10), blurRadius: 22),
          ],
        ),
        child: CustomPaint(painter: _Donut(n)),
      ),
    ),
  );
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: _size,
      height: _size,
      child: ColoredBox(
        color: fullBleed ? n.surface : Colors.transparent,
        child: Center(child: tile),
      ),
    ),
  );
}

Future<void> _render(WidgetTester tester, String path, {required bool fullBleed}) async {
  final key = GlobalKey();
  tester.view.physicalSize = const Size(_size, _size);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: _icon(fullBleed: fullBleed),
    ),
  );
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File(path).writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

void main() {
  testWidgets('generate app icons', (tester) async {
    addTearDown(tester.view.reset);
    await _render(tester, 'assets/icon/app_icon.png', fullBleed: false);
    await _render(tester, 'assets/icon/app_icon_ios.png', fullBleed: true);
    expect(File('assets/icon/app_icon.png').lengthSync(), greaterThan(10000));
  });
}
