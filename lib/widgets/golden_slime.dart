import 'package:flutter/material.dart';

import '../providers/game_provider.dart';

/// A small golden slime that appears on screen with a slight chance when
/// the user taps. Tap → grants a rush booster via [onCatch]. Times out
/// silently after [slimeLifetimeMs] with [onTimeout].
class GoldenSlime extends StatefulWidget {
  final VoidCallback onCatch;
  final VoidCallback onTimeout;
  const GoldenSlime({
    super.key,
    required this.onCatch,
    required this.onTimeout,
  });

  @override
  State<GoldenSlime> createState() => _GoldenSlimeState();
}

class _GoldenSlimeState extends State<GoldenSlime>
    with TickerProviderStateMixin {
  late final AnimationController _lifeC;
  late final AnimationController _pulseC;
  bool _caught = false;

  @override
  void initState() {
    super.initState();
    _lifeC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: slimeLifetimeMs),
    )..forward().whenComplete(() {
        if (mounted && !_caught) widget.onTimeout();
      });
    _pulseC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lifeC.dispose();
    _pulseC.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_caught) return;
    _caught = true;
    widget.onCatch();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_lifeC, _pulseC]),
        builder: (context, _) {
          // Fade in quickly, stay, fade out in the last 20% of life.
          final life = _lifeC.value;
          final opacity = life < 0.1
              ? life / 0.1
              : life > 0.8
                  ? (1.0 - (life - 0.8) / 0.2).clamp(0.0, 1.0)
                  : 1.0;
          final pulse = 1.0 + 0.12 * _pulseC.value;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: pulse,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFF176), Color(0xFFFFB300)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.55),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.monetization_on,
                      color: Color(0xFF7A4F00), size: 32),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
