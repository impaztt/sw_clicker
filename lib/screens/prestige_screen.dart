import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../providers/game_provider.dart';

class PrestigeScreen extends ConsumerWidget {
  const PrestigeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final available = game.prestigeSoulsAvailable;
    final canPrestige = available > 0;
    final currentPct = ((game.prestigeMultiplier - 1) * 100).toStringAsFixed(0);
    final nextPct =
        (((1 + (game.prestigeSouls + available) * 0.02) - 1) * 100)
            .toStringAsFixed(0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              '환생',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '검의 혼을 얻어 영구적으로 강해집니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            _StatCard(
              icon: Icons.auto_awesome,
              iconColor: const Color(0xFF00695C),
              label: '보유 검의 혼',
              value: '${game.prestigeSouls}',
              subValue: '영구 배율 +$currentPct%',
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.trending_up,
              iconColor: AppColors.deepCoral,
              label: '환생 시 획득',
              value: '+$available 소울',
              subValue: canPrestige
                  ? '환생 후 영구 배율 +$nextPct%'
                  : '최소 누적 골드 1B 필요',
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.history_toggle_off,
              iconColor: AppColors.mint,
              label: '환생 횟수',
              value: '${game.prestigeCount}',
              subValue:
                  '누적 골드 ${NumberFormatter.format(game.totalGoldEarned)}',
            ),
            const Spacer(),
            FilledButton(
              onPressed: canPrestige
                  ? () => _confirmPrestige(context, ref, available, nextPct)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    canPrestige ? AppColors.coral : Colors.grey.shade300,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text(
                canPrestige ? '환생하기 (+$available 소울)' : '아직 환생할 수 없어요',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '골드, 업그레이드, 동료 레벨이 초기화됩니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPrestige(
    BuildContext context,
    WidgetRef ref,
    int gain,
    String nextPct,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('정말 환생할까요?'),
        content: Text(
          '+$gain 검의 혼을 얻고 영구 배율이 +$nextPct%가 됩니다.\n'
          '골드·업그레이드·동료 레벨은 모두 초기화됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('환생'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(gameProvider.notifier).prestige();
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subValue;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subValue,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00695C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
