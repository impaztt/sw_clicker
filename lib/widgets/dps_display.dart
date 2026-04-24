import 'package:flutter/material.dart';
import '../core/number_format.dart';
import '../core/theme.dart';

class DpsDisplay extends StatelessWidget {
  final double dps;
  const DpsDisplay({super.key, required this.dps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, size: 18, color: Color(0xFF00897B)),
          const SizedBox(width: 4),
          Text(
            '${NumberFormatter.formatPrecise(dps)}/초',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00695C),
            ),
          ),
        ],
      ),
    );
  }
}
