// Run: dart tool/gen_icon.dart
// Generates Ishbor briefcase launcher icons in all Android mipmap densities
// using only dart:ui (no external packages needed).

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

// PNG encoder (hand-written minimal, no package dependency)
Uint8List _encodePng(int width, int height, Uint8List rgba) {
  // We delegate to Flutter's dart:ui Image encoder instead
  throw UnimplementedError('use encodeImage');
}

Future<void> main() async {
  const sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in sizes.entries) {
    final size = entry.value.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, size, size),
    );

    _drawIcon(canvas, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(entry.value, entry.value);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final path = 'android/app/src/main/res/${entry.key}/ic_launcher.png';
    File(path).writeAsBytesSync(bytes);
    print('Written $path  (${entry.value}x${entry.value})');
  }
  print('Done!');
}

void _drawIcon(ui.Canvas canvas, double s) {
  // Background gradient — deep blue
  final bgPaint = ui.Paint()
    ..shader = ui.Gradient.linear(
      ui.Offset(0, 0),
      ui.Offset(s, s),
      [const ui.Color(0xFF1B4FD8), const ui.Color(0xFF0EA5E9)],
    );

  final bgRRect = ui.RRect.fromRectAndRadius(
    ui.Rect.fromLTWH(0, 0, s, s),
    ui.Radius.circular(s * 0.22),
  );
  canvas.drawRRect(bgRRect, bgPaint);

  final white = ui.Paint()
    ..color = const ui.Color(0xFFFFFFFF)
    ..style = ui.PaintingStyle.fill;

  final whiteSt = ui.Paint()
    ..color = const ui.Color(0xFFFFFFFF)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = s * 0.045
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;

  // ── Briefcase / diplomat body ──────────────────────────────────────
  final bx = s * 0.18; // left
  final by = s * 0.42; // top
  final bw = s * 0.64; // width
  final bh = s * 0.36; // height
  final br = s * 0.07; // corner radius

  final bodyPath = ui.Path()
    ..addRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(bx, by, bw, bh),
        ui.Radius.circular(br),
      ),
    );
  canvas.drawPath(
      bodyPath,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = s * 0.045
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round);

  // Center clasp / handle line
  canvas.drawLine(
    ui.Offset(s * 0.50, by),
    ui.Offset(s * 0.50, by + bh),
    whiteSt,
  );

  // Horizontal middle band
  canvas.drawLine(
    ui.Offset(bx, by + bh * 0.48),
    ui.Offset(bx + bw, by + bh * 0.48),
    whiteSt,
  );

  // ── Handle (top) ──────────────────────────────────────────────────
  final hx = s * 0.36;
  final hw = s * 0.28;
  final hBot = by + s * 0.01;
  final hTop = s * 0.26;
  final hr = s * 0.06;

  final handlePath = ui.Path()
    ..moveTo(hx, hBot)
    ..lineTo(hx, hTop + hr)
    ..arcToPoint(
      ui.Offset(hx + hr, hTop),
      radius: ui.Radius.circular(hr),
      clockwise: false,
    )
    ..lineTo(hx + hw - hr, hTop)
    ..arcToPoint(
      ui.Offset(hx + hw, hTop + hr),
      radius: ui.Radius.circular(hr),
      clockwise: false,
    )
    ..lineTo(hx + hw, hBot);

  canvas.drawPath(handlePath, whiteSt);
}
