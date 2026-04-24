import 'package:flutter/material.dart';
import '../core/number_format.dart';
import '../core/theme.dart';

class GoldDisplay extends StatelessWidget {
  final double amount;
  const GoldDisplay({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.yellow, size: 32),
          const SizedBox(width: 10),
          Text(
            NumberFormatter.format(amount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.deepCoral,
            ),
          ),
        ],
      ),
    );
  }
}
