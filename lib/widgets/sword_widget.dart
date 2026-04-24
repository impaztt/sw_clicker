import 'package:flutter/material.dart';
import '../core/theme.dart';

class SwordWidget extends StatefulWidget {
  final void Function(Offset globalPosition) onTap;
  final double size;

  const SwordWidget({
    super.key,
    required this.onTap,
    this.size = 240,
  });

  @override
  State<SwordWidget> createState() => _SwordWidgetState();
}

class _SwordWidgetState extends State<SwordWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);
    _rotation = Tween<double>(begin: 0, end: 0.08)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    if (_controller.isAnimating) {
      _controller.reset();
    }
    _controller.forward().then((_) {
      if (mounted) _controller.reverse();
    });
    widget.onTap(details.globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.rotate(
            angle: _rotation.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          );
        },
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
                      AppColors.coral.withValues(alpha: 0.30),
                      AppColors.coral.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
              CustomPaint(
                size: Size(widget.size * 0.7, widget.size * 0.85),
                painter: _SwordPainter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwordPainter extends CustomPainter {
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

    canvas.drawPath(bladePath, Paint()..color = AppColors.blade);

    final bladeShadowPath = Path()
      ..moveTo(cx + w * 0.04, h * 0.10)
      ..lineTo(cx + w * 0.10, h * 0.14)
      ..lineTo(cx + w * 0.10, h * 0.58)
      ..lineTo(cx + w * 0.04, h * 0.58)
      ..close();
    canvas.drawPath(
      bladeShadowPath,
      Paint()..color = AppColors.bladeShadow.withValues(alpha: 0.6),
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
    canvas.drawRRect(guardRRect, Paint()..color = AppColors.yellow);
    canvas.drawRRect(guardRRect, outline);

    final handleRect = Rect.fromLTWH(
      cx - w * 0.06,
      h * 0.64,
      w * 0.12,
      h * 0.24,
    );
    final handleRRect =
        RRect.fromRectAndRadius(handleRect, const Radius.circular(8));
    canvas.drawRRect(handleRRect, Paint()..color = AppColors.handle);
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
      Paint()..color = AppColors.yellow,
    );
    canvas.drawCircle(Offset(cx, h * 0.92), w * 0.09, outline);

    canvas.drawCircle(
      Offset(cx - w * 0.025, h * 0.90),
      w * 0.025,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
