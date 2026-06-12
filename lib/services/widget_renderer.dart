import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../core/ui/tile_painter.dart';
import '../data/models/task.dart';

class WidgetRenderer {
  static const double _tileSize = 180.0;
  static const double _spacing = 6.0;
  static const double _padding = 8.0;
  static const double _radius = 16.0;

  static Future<void> renderAndSave({
    required List<Task> tasks,
    String? activeTaskName,
    int gridSize = 3,
  }) async {
    final total = gridSize * gridSize;
    final cellsToRender = total.clamp(0, 36);

    final gridPixelSize =
        _tileSize * gridSize + _spacing * (gridSize - 1) + _padding * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, gridPixelSize, gridPixelSize),
    );

    final bgPaint = Paint()..color = const Color(0xFF121212);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gridPixelSize, gridPixelSize),
      bgPaint,
    );

    for (int i = 0; i < cellsToRender; i++) {
      final col = i % gridSize;
      final row = i ~/ gridSize;
      final x = _padding + col * (_tileSize + _spacing);
      final y = _padding + row * (_tileSize + _spacing);

      canvas.save();
      canvas.translate(x, y);

      if (i < tasks.length) {
        final task = tasks[i];
        final isActive = task.name == activeTaskName;
        final data = TileRenderData(
          name: task.name,
          color: Color(task.color),
          isActive: isActive,
        );
        paintTileContent(
          canvas,
          Size(_tileSize, _tileSize),
          data,
          isDark: true,
          glowIntensity: isActive ? 1.0 : 0.0,
        );
      } else {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, _tileSize, _tileSize),
          const Radius.circular(16),
        );
        final bg = Paint()..color = Colors.white.withAlpha(10);
        canvas.drawRRect(rrect, bg);
        final border = Paint()
          ..color = Colors.white.withAlpha(20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawRRect(rrect, border);
      }

      canvas.restore();
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      gridPixelSize.toInt(),
      gridPixelSize.toInt(),
    );
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final pngBytes = byteData!.buffer.asUint8List();

    await HomeWidget.saveWidgetData(
        'launchpad_grid', base64Encode(pngBytes));
    await HomeWidget.saveWidgetData('launchpad_grid_size', gridSize);
  }
}
