import 'package:flutter/material.dart';

import '../core/number_format.dart';
import '../core/theme.dart';

class UpgradeTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String name;
  final String description;
  final int level;
  final double cost;
  final int buyCount;
  final String gainLabel;
  final String? milestoneLabel;
  final bool affordable;
  final VoidCallback onBuy;

  const UpgradeTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.name,
    required this.description,
    required this.level,
    required this.cost,
    required this.buyCount,
    required this.gainLabel,
    required this.affordable,
    required this.onBuy,
    this.milestoneLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mint.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Lv $level',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00695C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gainLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00695C),
                    ),
                  ),
                  if (milestoneLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      milestoneLabel!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _BuyButton(
              cost: cost,
              buyCount: buyCount,
              affordable: affordable,
              onBuy: onBuy,
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final double cost;
  final int buyCount;
  final bool affordable;
  final VoidCallback onBuy;

  const _BuyButton({
    required this.cost,
    required this.buyCount,
    required this.affordable,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final bg = affordable ? AppColors.coral : Colors.grey.shade300;
    final fg = affordable ? Colors.white : Colors.grey.shade600;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: affordable ? onBuy : null,
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Text(
                'x$buyCount',
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on, color: fg, size: 16),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      NumberFormatter.format(cost),
                      style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
