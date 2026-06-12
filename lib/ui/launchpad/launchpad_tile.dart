import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/ui/tile_painter.dart';
import '../../core/utils/color_utils.dart';

class _BreathingCurve extends Curve {
  @override
  double transformInternal(double t) {
    const inhaleEnd = 4.0 / 20.0;
    const holdEnd = 11.0 / 20.0;

    if (t <= inhaleEnd) {
      final p = t / inhaleEnd;
      return 0.4 + 0.6 * (1 - cos(p * pi / 2));
    } else if (t <= holdEnd) {
      return 1.0;
    } else {
      final p = (t - holdEnd) / (1.0 - holdEnd);
      return 0.4 + 0.6 * cos(p * pi / 2);
    }
  }
}

class LaunchpadTile extends StatefulWidget {
  final String name;
  final int color;
  final bool isActive;
  final String? elapsed;
  final int? dailyTotal;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const LaunchpadTile({
    super.key,
    required this.name,
    required this.color,
    required this.isActive,
    this.elapsed,
    this.dailyTotal,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<LaunchpadTile> createState() => _LaunchpadTileState();
}

class _LaunchpadTileState extends State<LaunchpadTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _glowAnim = CurvedAnimation(
      parent: _glowCtrl,
      curve: const _BreathingCurve(),
    );
    if (widget.isActive) {
      _glowCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(LaunchpadTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _glowCtrl.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _glowCtrl.stop();
      _glowCtrl.reset();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clr = colorFromInt(widget.color);
    final active = widget.isActive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: active ? null : (_) => setState(() => _pressed = true),
      onTapUp: active ? null : (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          final glowIntensity = active ? _glowAnim.value : 0.0;
          final pressScale = _pressed ? 0.92 : 1.0;

          return Transform.scale(
            scale: pressScale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: TilePainter(
                  TileRenderData(
                    name: widget.name,
                    color: clr,
                    isActive: active,
                    elapsed: widget.elapsed,
                    dailyTotal: widget.dailyTotal,
                  ),
                  isDark: isDark,
                  glowIntensity: glowIntensity,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
