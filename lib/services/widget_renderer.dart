import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../core/ui/tile_painter.dart';
import '../data/models/task.dart';

class WidgetRenderer {
  static const double _tileSize = 300.0;

  static Future<void> renderAndSave({
    required List<Task> tasks,
    String? activeTaskName,
  }) async {
    final tiles = <String>[];

    for (int i = 0; i < 9; i++) {
      if (i < tasks.length) {
        final task = tasks[i];
        final isActive = task.name == activeTaskName;
        final data = TileRenderData(
          name: task.name,
          color: Color(task.color),
          isActive: isActive,
        );
        final png = await _renderTileToPng(data);
        tiles.add(base64Encode(png));
      } else {
        final png = await _renderEmptyTile();
        tiles.add(base64Encode(png));
      }
    }

    await HomeWidget.saveWidgetData('launchpad_tiles', jsonEncode(tiles));
  }

  static Future<Uint8List> _renderTileToPng(TileRenderData data) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _tileSize, _tileSize),
    );

    paintTileContent(
      canvas,
      Size(_tileSize, _tileSize),
      data,
      isDark: true,
      glowIntensity: data.isActive ? 1.0 : 0.0,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _tileSize.toInt(),
      _tileSize.toInt(),
    );
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  static Future<Uint8List> _renderEmptyTile() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _tileSize, _tileSize),
    );

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, _tileSize, _tileSize),
      const Radius.circular(16),
    );

    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(10);
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _tileSize.toInt(),
      _tileSize.toInt(),
    );
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }
}
