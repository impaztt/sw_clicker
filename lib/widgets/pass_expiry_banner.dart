import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/game_provider.dart';
import '../services/iap_service.dart';

/// Reminds the player to renew an active pass when it's within the warning
/// window of expiring. Shows the most-pressing pass at most.
class PassExpiryBanner extends ConsumerWidget {
  const PassExpiryBanner({super.key});

  static const int _warnDays = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final now = DateTime.now();

    // Pick whichever pass is closer to expiring inside the warn window.
    _ActivePass? selected;
    final season = game.seasonPassExpiresAt;
    if (season != null && season.isAfter(now)) {
      final days = season.difference(now).inDays + 1;
      if (days <= _warnDays) {
        selected = _ActivePass(
          label: '시즌 패스',
          daysRemaining: days,
          productId: premiumSeasonPassProductId,
          color: const Color(0xFF7C4DFF),
        );
      }
    }
    final monthly = game.monthlyPassExpiresAt;
    if (monthly != null && monthly.isAfter(now)) {
      final days = monthly.difference(now).inDays + 1;
      if (days <= _warnDays && (selected == null || days < selected.daysRemaining)) {
        selected = _ActivePass(
          label: '월간 정수 보급권',
          daysRemaining: days,
          productId: premiumMonthlyEssencePassProductId,
          color: const Color(0xFF26A69A),
        );
      }
    }
    if (selected == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: selected.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => IapService.instance.buy(
            selected!.productId,
            consumable: false,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: selected.color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selected.label} 만료까지 ${selected.daysRemaining}일',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected.color,
                        ),
                      ),
                      Text(
                        '터치해서 연장하기',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: selected.color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivePass {
  final String label;
  final int daysRemaining;
  final String productId;
  final Color color;
  const _ActivePass({
    required this.label,
    required this.daysRemaining,
    required this.productId,
    required this.color,
  });
}
