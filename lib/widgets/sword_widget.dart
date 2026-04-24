import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/sword.dart';

const _defaultVisual = SwordVisual(
  bladeColor: AppColors.blade,
  bladeAccent: AppColors.bladeShadow,
  guardColor: AppColors.yellow,
  handleColor: AppColors.handle,
  pommelColor: AppColors.yellow,
  auraColor: AppColors.coral,
  auraIntensity: 0.3,
);

class SwordWidget extends StatefulWidget {
  final void Function(Offset globalPosition) onTap;
  final double size;
  final SwordVisual visual;

  const SwordWidget({
    super.key,
    required this.onTap,
    this.size = 240,
    this.visual = _defaultVisual,
  });

  @override
  State<SwordWidget> createState() => _SwordWidgetState();
}

class _SwordWidgetState extends State<SwordWidget>
    with TickerProviderStateMixin {
  late final AnimationController _tapController;
  late final AnimationController _sparkleController;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_tapController);
    _rotation = Tween<double>(begin: 0, end: 0.08)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_tapController);
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _tapController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    if (_tapController.isAnimating) _tapController.reset();
    _tapController.forward().then((_) {
      if (mounted) _tapController.reverse();
    });
    widget.onTap(details.globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visual;
    return GestureDetector(
      onTapDown: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_tapController, _sparkleController]),
        builder: (_, __) {
          return Transform.rotate(
            angle: _rotation.value,
            child: Transform.scale(
              scale: _scale.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            v.auraColor.withValues(alpha: v.auraIntensity),
                            v.auraColor.withValues(alpha: v.auraIntensity * 0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.65, 1.0],
                        ),
                      ),
                    ),
                    if (v.sparkle != SparkleStyle.none)
                      CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _SparklePainter(
                          style: v.sparkle,
                          color: v.auraColor,
                          t: _sparkleController.value,
                        ),
                      ),
                    CustomPaint(
                      size: Size(widget.size * 0.7, widget.size * 0.85),
                      painter: _SwordPainter(v),
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

class _SwordPainter extends CustomPainter {
  final SwordVisual v;
  _SwordPainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final outline = Paint()
      ..color = AppColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;

    final bladePath = Path()
      ..moveTo(cx, h * 0.04)
      ..lineTo(cx + w * 0.10, h * 0.14)
      ..lineTo(cx + w * 0.10, h * 0.58)
      ..lineTo(cx - w * 0.10, h * 0.58)
      ..lineTo(cx - w * 0.10, h * 0.14)
      ..close();

    canvas.drawPath(bladePath, Paint()..color = v.bladeColor);

    final bladeShadowPath = Path()
      ..moveTo(cx + w * 0.04, h * 0.10)
      ..lineTo(cx + w * 0.10, h * 0.14)
      ..lineTo(cx + w * 0.10, h * 0.58)
      ..lineTo(cx + w * 0.04, h * 0.58)
      ..close();
    canvas.drawPath(
      bladeShadowPath,
      Paint()..color = v.bladeAccent.withValues(alpha: 0.6),
    );

    canvas.drawLine(
      Offset(cx, h * 0.10),
      Offset(cx, h * 0.55),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(bladePath, outline);

    final guardRect = Rect.fromLTWH(
      cx - w * 0.36,
      h * 0.58,
      w * 0.72,
      h * 0.06,
    );
    final guardRRect =
        RRect.fromRectAndRadius(guardRect, const Radius.circular(6));
    canvas.drawRRect(guardRRect, Paint()..color = v.guardColor);
    canvas.drawRRect(guardRRect, outline);

    final handleRect = Rect.fromLTWH(
      cx - w * 0.06,
      h * 0.64,
      w * 0.12,
      h * 0.24,
    );
    final handleRRect =
        RRect.fromRectAndRadius(handleRect, const Radius.circular(8));
    canvas.drawRRect(handleRRect, Paint()..color = v.handleColor);
    canvas.drawRRect(handleRRect, outline);

    final handleHighlight = Rect.fromLTWH(
      cx - w * 0.04,
      h * 0.66,
      w * 0.025,
      h * 0.20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleHighlight, const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    canvas.drawCircle(
      Offset(cx, h * 0.92),
      w * 0.09,
      Paint()..color = v.pommelColor,
    );
    canvas.drawCircle(Offset(cx, h * 0.92), w * 0.09, outline);

    canvas.drawCircle(
      Offset(cx - w * 0.025, h * 0.90),
      w * 0.025,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _SwordPainter oldDelegate) =>
      oldDelegate.v != v;
}

class _SparklePainter extends CustomPainter {
  final SparkleStyle style;
  final Color color;
  final double t;

  _SparklePainter({required this.style, required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.36;
    final count = style == SparkleStyle.orbiting ? 6 : 3;
    final baseR = style == SparkleStyle.orbiting
        ? 5.0
        : style == SparkleStyle.bright
            ? 3.5
            : 2.5;
    for (int i = 0; i < count; i++) {
      final phase = (t + i / count) % 1.0;
      final angle = phase * 2 * math.pi;
      final dx = cx + math.cos(angle) * radius;
      final dy = cy + math.sin(angle) * radius * 0.85;
      final alpha = (math.sin(phase * math.pi) * 0.9 + 0.1).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(dx, dy),
        baseR,
        Paint()..color = color.withValues(alpha: alpha),
      );
      canvas.drawCircle(
        Offset(dx, dy),
        baseR * 2,
        Paint()..color = color.withValues(alpha: alpha * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}
