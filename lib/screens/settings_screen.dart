import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../providers/game_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 4),
          const Text(
            '통계 & 설정',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: '통계'),
          const SizedBox(height: 8),
          _StatGrid(
            items: [
              _StatItem(
                icon: Icons.touch_app,
                color: AppColors.coral,
                label: '총 터치',
                value: NumberFormatter.format(game.totalTaps.toDouble()),
              ),
              _StatItem(
                icon: Icons.timer,
                color: const Color(0xFF00695C),
                label: '플레이 시간',
                value: _fmtDuration(game.playTimeSeconds),
              ),
              _StatItem(
                icon: Icons.bolt,
                color: const Color(0xFF8D6E00),
                label: '최고 DPS',
                value: NumberFormatter.format(game.maxDpsEver),
              ),
              _StatItem(
                icon: Icons.monetization_on,
                color: AppColors.deepCoral,
                label: '평생 골드',
                value: NumberFormatter.format(game.lifetimeGold),
              ),
              _StatItem(
                icon: Icons.auto_awesome,
                color: AppColors.mint,
                label: '환생 횟수',
                value: '${game.prestigeCount}',
              ),
              _StatItem(
                icon: Icons.trending_up,
                color: const Color(0xFF7E57C2),
                label: '영구 배율',
                value: '+${((game.prestigeMultiplier - 1) * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: '설정'),
          const SizedBox(height: 8),
          _ToggleRow(
            icon: Icons.vibration,
            label: '햅틱 (터치 진동)',
            value: game.haptic,
            onChanged: (v) => ref.read(gameProvider.notifier).setHaptic(v),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: '데이터'),
          const SizedBox(height: 8),
          _DangerButton(
            onPressed: () => _confirmReset(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('정말 초기화할까요?'),
        content: const Text(
          '모든 진행도, 골드, 동료 레벨, 검의 혼, 통계가 삭제돼요.\n'
          '이 작업은 되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(gameProvider.notifier).resetAll();
    }
  }

  String _fmtDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Colors.black.withValues(alpha: 0.55),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _StatGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: items,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.coral,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _DangerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
      label: const Text(
        '저장 초기화',
        style: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: Colors.redAccent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
