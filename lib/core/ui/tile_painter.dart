import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TileRenderData {
  final String name;
  final Color color;
  final bool isActive;
  final String? elapsed;
  final int? dailyTotal;

  const TileRenderData({
    required this.name,
    required this.color,
    required this.isActive,
    this.elapsed,
    this.dailyTotal,
  });
}

class TilePainter extends CustomPainter {
  final TileRenderData data;
  final bool isDark;
  final double glowIntensity;

  TilePainter(
    this.data, {
    this.isDark = true,
    this.glowIntensity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintTileContent(canvas, size, data,
        isDark: isDark, glowIntensity: glowIntensity);
  }

  @override
  bool shouldRepaint(TilePainter oldDelegate) =>
      oldDelegate.data.name != data.name ||
      oldDelegate.data.color != data.color ||
      oldDelegate.data.isActive != data.isActive ||
      oldDelegate.data.elapsed != data.elapsed ||
      oldDelegate.data.dailyTotal != data.dailyTotal ||
      oldDelegate.isDark != isDark ||
      oldDelegate.glowIntensity != glowIntensity;
}

void paintTileContent(
  Canvas canvas,
  Size size,
  TileRenderData data, {
  bool isDark = true,
  double glowIntensity = 0.0,
}) {
  final clr = data.color;
  final active = data.isActive;
  final w = size.width;
  final h = size.height;
  final g = glowIntensity;

  final bgColors = active
      ? [
          clr.withAlpha((255 * g).round()),
          clr,
          clr.withAlpha((200 * g).round()),
        ]
      : isDark
          ? [clr.withAlpha(60), clr.withAlpha(80), clr.withAlpha(40)]
          : [clr.withAlpha(30), clr.withAlpha(50), clr.withAlpha(20)];

  final borderColor = active
      ? clr.withAlpha((255 * g).round())
      : clr.withAlpha(isDark ? 80 : 40);
  final borderWidth = active ? 2.5 : 1.0;

  final rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, w, h),
    const Radius.circular(16),
  );

  canvas.save();
  canvas.clipRRect(rrect);

  final bgPaint = Paint()
    ..shader = ui.Gradient.radial(
      Offset(w / 2, h / 2),
      w * 0.4,
      bgColors,
      [0.0, 0.5, 1.0],
      TileMode.clamp,
    );
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

  if (active) {
    final shadowPaint = Paint()
      ..color = clr.withAlpha((120 * g).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRRect(rrect, shadowPaint);

    final shadowPaint2 = Paint()
      ..color = clr.withAlpha((80 * g).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
    canvas.drawRRect(rrect, shadowPaint2);

    final glowShader = ui.Gradient.radial(
      Offset(w / 2, h / 2),
      w * 0.45,
      [
        clr.withAlpha(0),
        clr.withAlpha((60 * g).round()),
        clr.withAlpha((40 * g).round()),
        clr.withAlpha(0),
      ],
      [0.7, 0.85, 0.92, 1.0],
      TileMode.clamp,
    );
    final glowPaint = Paint()..shader = glowShader;
    canvas.drawRRect(rrect, glowPaint);

    final cornerPaint = Paint()
      ..color = clr.withAlpha((100 * g).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final c in [
      Offset(0, 0),
      Offset(w, 0),
      Offset(w, h),
      Offset(0, h),
    ]) {
      canvas.drawCircle(c, 12, cornerPaint);
    }
  } else {
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, shadowPaint);
  }

  canvas.restore();

  final borderPaint = Paint()
    ..color = borderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = borderWidth;
  canvas.drawRRect(rrect, borderPaint);

  final nameStyle = ui.TextStyle(
    color: active ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
    fontSize: 14,
  );
  final namePara = ui.ParagraphBuilder(ui.ParagraphStyle(
    textAlign: TextAlign.center,
    maxLines: 2,
    ellipsis: '...',
  ))
    ..pushStyle(nameStyle)
    ..addText(data.name);
  final nameText = namePara.build();
  nameText.layout(ui.ParagraphConstraints(width: w - 16));

  double textBlockHeight = nameText.height;
  final extraLines = <ui.Paragraph>[];

  final hasElapsed = active && data.elapsed != null;
  final hasDaily = data.dailyTotal != null && data.dailyTotal! > 0;

  if (hasElapsed) {
    final timerStyle = ui.TextStyle(
      color: Colors.white.withAlpha(230),
      fontSize: 20,
      fontWeight: FontWeight.w700,
      fontFeatures: [const FontFeature.tabularFigures()],
    );
    final timerPara = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
    ))
      ..pushStyle(timerStyle)
      ..addText(data.elapsed!);
    final timerText = timerPara.build();
    timerText.layout(ui.ParagraphConstraints(width: w - 16));
    textBlockHeight += 4 + timerText.height;
    extraLines.add(timerText);
  }

  if (hasDaily) {
    final dailyStyle = ui.TextStyle(
      color: active
          ? Colors.white.withAlpha(180)
          : Colors.white.withAlpha(100),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFeatures: [const FontFeature.tabularFigures()],
    );
    final dailyValue = _formatDuration(data.dailyTotal!);
    final dailyPara = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
    ))
      ..pushStyle(dailyStyle)
      ..addText(dailyValue);
    final dailyText = dailyPara.build();
    dailyText.layout(ui.ParagraphConstraints(width: w - 16));
    textBlockHeight += 2 + dailyText.height;
    extraLines.add(dailyText);
  }

  const dotSize = 10.0;
  if (active) {
    textBlockHeight += 2 + dotSize;
  }

  double yOffset = (h - textBlockHeight) / 2;

  canvas.drawParagraph(nameText, Offset((w - nameText.width) / 2, yOffset));
  yOffset += nameText.height;

  for (final line in extraLines) {
    yOffset += 4;
    if (line == extraLines.first) yOffset -= 2;
    canvas.drawParagraph(line, Offset((w - line.width) / 2, yOffset));
    yOffset += line.height;
  }

  if (active) {
    yOffset += 2;
    final dotPaint = Paint()..color = Colors.white.withAlpha(200);
    canvas.drawCircle(
      Offset(w / 2, yOffset + dotSize / 2),
      dotSize / 2,
      dotPaint,
    );
  }
}

String _formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
