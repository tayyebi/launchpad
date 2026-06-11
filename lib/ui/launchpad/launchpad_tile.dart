import 'package:flutter/material.dart';
import '../../core/utils/color_utils.dart';

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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didUpdateWidget(LaunchpadTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _glowCtrl.reset();
      _glowCtrl.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _glowCtrl.stop();
      _glowCtrl.reset();
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    if (active)
                      clr.withAlpha((255 * glowIntensity).round())
                    else
                      clr.withAlpha(isDark ? 60 : 30),
                    if (active) clr else clr.withAlpha(isDark ? 80 : 50),
                    if (active)
                      clr.withAlpha((200 * glowIntensity).round())
                    else
                      clr.withAlpha(isDark ? 40 : 20),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: active
                      ? clr.withAlpha((255 * glowIntensity).round())
                      : clr.withAlpha(isDark ? 80 : 40),
                  width: active ? 2.5 : 1.0,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: clr.withAlpha((120 * glowIntensity).round()),
                      blurRadius: 24 + 16 * glowIntensity,
                      spreadRadius: 4 * glowIntensity,
                    ),
                  if (active)
                    BoxShadow(
                      color: clr.withAlpha((80 * glowIntensity).round()),
                      blurRadius: 48,
                      spreadRadius: 8 * glowIntensity,
                    ),
                  if (!active)
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: CustomPaint(
                painter: active
                    ? _GlowBorderPainter(clr: clr, intensity: glowIntensity)
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          widget.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black54),
                            fontWeight: active ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                            shadows: active
                                ? [
                                    Shadow(
                                      color: clr.withAlpha(200),
                                      blurRadius: 8 * glowIntensity,
                                    ),
                                  ]
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (active && widget.elapsed != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.elapsed!,
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            shadows: [
                              Shadow(
                                color: clr.withAlpha(200),
                                blurRadius: 12 * glowIntensity,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.dailyTotal != null && widget.dailyTotal! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _formatDuration(widget.dailyTotal!),
                          style: TextStyle(
                            color: active
                                ? Colors.white.withAlpha(180)
                                : Colors.white.withAlpha(100),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    if (active)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.fiber_manual_record,
                          size: 10,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  final Color clr;
  final double intensity;

  _GlowBorderPainter({required this.clr, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          clr.withAlpha(0),
          clr.withAlpha((60 * intensity).round()),
          clr.withAlpha((40 * intensity).round()),
          clr.withAlpha(0),
        ],
        stops: const [0.7, 0.85, 0.92, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      paint,
    );

    final cornerPaint = Paint()
      ..color = clr.withAlpha((100 * intensity).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    const cornerLength = 12.0;
    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    for (final c in corners) {
      canvas.drawCircle(c, cornerLength, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(_GlowBorderPainter old) => old.intensity != intensity;
}
