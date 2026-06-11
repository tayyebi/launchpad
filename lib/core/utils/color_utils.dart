import 'package:flutter/material.dart';

const presetColors = [
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF5722),
  Color(0xFF9C27B0),
  Color(0xFFFFC107),
  Color(0xFFE91E63),
  Color(0xFF00BCD4),
  Color(0xFFFF9800),
  Color(0xFF607D8B),
  Color(0xFF795548),
  Color(0xFF3F51B5),
  Color(0xFF009688),
  Color(0xFFCDDC39),
  Color(0xFFFFEB3B),
  Color(0xFFFF4081),
  Color(0xFF7C4DFF),
];

Color colorFromInt(int value) => Color(value);
int intFromColor(Color c) => c.value;

int colorFromName(String name) {
  final hash = name.codeUnits.fold<int>(0, (h, c) => h * 31 + c);
  final hue = hash.abs() % 360;
  return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.7, 0.8).toColor().value;
}
