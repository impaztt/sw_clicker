import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/sword.dart';

/// Small static preview of a sword (no tap, no sparkle animation).
class SwordPreview extends StatelessWidget {
  final SwordVisual visual;
  final double size;
  final bool locked;

  const SwordPreview({
    super.key,
    required this.visual,
    this.size = 80,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PreviewPainter(visual: visual, locked: locked),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final SwordVisual visual;
  final bool locked;

  _PreviewPainter({required this.visual, required this.locked});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // aura
    if (!locked) {
      canvas.drawCircle(
        Offset(cx, h / 2),
        w * 0.48,
        Paint()
          ..shader = RadialGradient(
            colors: [
              visual.auraColor.withValues(alpha: visual.auraIntensity * 0.8),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, h / 2), radius: w * 0.48),
          ),
      );
    }

    final blade = locked ? const Color(0xFF424242) : visual.bladeColor;
    final bladeAccent =
        locked ? const Color(0xFF212121) : visual.bladeAccent;
    final guard = locked ? const Color(0xFF424242) : visual.guardColor;
    final handle = locked ? const Color(0xFF212121) : visual.handleColor;
    final pommel = locked ? const Color(0xFF424242) : visual.pommelColor;

    final outline = Paint()
      ..color = AppColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    final bladePath = Path()
      ..moveTo(cx, h * 0.08)
      ..lineTo(cx + w * 0.10, h * 0.18)
      ..lineTo(cx + w * 0.10, h * 0.58)
      ..lineTo(cx - w * 0.10, h * 0.58)
      ..lineTo(cx - w * 0.10, h * 0.18)
      ..close();

    canvas.drawPath(bladePath, Paint()..color = blade);

    final bladeShadowPath = Path()
      ..moveTo(cx + w * 0.04, h * 0.14)
      ..lineTo(cx + w * 0.10, h * 0.18)
      ..lineTo(cx + w * 0.10, h * 0.58)
      ..lineTo(cx + w * 0.04, h * 0.58)
      ..close();
    canvas.drawPath(
      bladeShadowPath,
      Paint()..color = bladeAccent.withValues(alpha: 0.6),
    );
    canvas.drawPath(bladePath, outline);

    final guardRect = Rect.fromLTWH(
      cx - w * 0.32,
      h * 0.58,
      w * 0.64,
      h * 0.06,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(guardRect, const Radius.circular(4)),
      Paint()..color = guard,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(guardRect, const Radius.circular(4)),
      outline,
    );

    final handleRect = Rect.fromLTWH(
      cx - w * 0.05,
      h * 0.64,
      w * 0.10,
      h * 0.20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(4)),
      Paint()..color = handle,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(4)),
      outline,
    );

    canvas.drawCircle(
      Offset(cx, h * 0.88),
      w * 0.075,
      Paint()..color = pommel,
    );
    canvas.drawCircle(Offset(cx, h * 0.88), w * 0.075, outline);

    if (locked) {
      canvas.drawCircle(
        Offset(cx, h * 0.5),
        w * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.1),
      );
      final tp = TextPainter(
        text: const TextSpan(
          text: '?',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, h * 0.5 - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) =>
      oldDelegate.visual != visual || oldDelegate.locked != locked;
}
