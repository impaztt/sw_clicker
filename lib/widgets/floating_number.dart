import 'package:flutter/material.dart';

import '../core/number_format.dart';
import '../core/theme.dart';

class FloatingNumberData {
  final int id;
  final Offset origin;
  final double amount;
  FloatingNumberData({
    required this.id,
    required this.origin,
    required this.amount,
  });
}

class FloatingNumberLayer extends StatelessWidget {
  final List<FloatingNumberData> items;
  final void Function(int id) onDone;

  const FloatingNumberLayer({
    super.key,
    required this.items,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final data in items)
            _FloatingNumber(
              key: ValueKey(data.id),
              data: data,
              onDone: () => onDone(data.id),
            ),
        ],
      ),
    );
  }
}

class _FloatingNumber extends StatefulWidget {
  final FloatingNumberData data;
  final VoidCallback onDone;

  const _FloatingNumber({
    super.key,
    required this.data,
    required this.onDone,
  });

  @override
  State<_FloatingNumber> createState() => _FloatingNumberState();
}

class _FloatingNumberState extends State<_FloatingNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final dy = -60.0 * t;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Positioned(
          left: widget.data.origin.dx - 40,
          top: widget.data.origin.dy + dy - 20,
          width: 80,
          child: Opacity(
            opacity: opacity,
            child: Center(
              child: Text(
                '+${NumberFormatter.format(widget.data.amount)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.deepCoral,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 4,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
