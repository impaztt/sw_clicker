import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/achievement_catalog.dart';
import '../providers/game_provider.dart';
import 'achievement_screen.dart';

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
                value:
                    '+${((game.prestigeMultiplier - 1) * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: '업적'),
          const SizedBox(height: 8),
          _AchievementLink(
            unlocked: game.unlockedAchievements.length,
            total: achievementCatalog.length,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementScreen()),
            ),
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
          const SizedBox(height: 8),
          _ToggleRow(
            icon: Icons.volume_up,
            label: '사운드',
            value: game.sound,
            onChanged: (v) => ref.read(gameProvider.notifier).setSound(v),
          ),
          const SizedBox(height: 8),
          _ToggleRow(
            icon: Icons.dark_mode,
            label: '다크 모드',
            value: game.darkMode,
            onChanged: (v) => ref.read(gameProvider.notifier).setDarkMode(v),
          ),
          const SizedBox(height: 8),
          _ToggleRow(
            icon: Icons.contrast,
            label: '고대비 모드',
            value: game.highContrast,
            onChanged: (v) =>
                ref.read(gameProvider.notifier).setHighContrast(v),
          ),
          const SizedBox(height: 8),
          _ToggleRow(
            icon: Icons.vibration,
            label: '일반 터치 진동 줄이기',
            value: game.reduceTapHaptics,
            onChanged: (v) =>
                ref.read(gameProvider.notifier).setReduceTapHaptics(v),
          ),
          const SizedBox(height: 8),
          _TextScaleSelector(
            value: game.textScale,
            onChanged: (v) => ref.read(gameProvider.notifier).setTextScale(v),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: '데이터'),
          const SizedBox(height: 8),
          if (game.timeGuardTriggered)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: const Text(
                '기기 시간 조작이 감지되어 오프라인 보상이 제한되었습니다.\n'
                '시간 자동 설정을 사용해 주세요.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('정말 초기화할까요?'),
        content: const Text(
          '모든 진행도, 골드, 동료 레벨, 환생 코인, 통계가 삭제돼요.\n'
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

class _AchievementLink extends StatelessWidget {
  final int unlocked;
  final int total;
  final VoidCallback onTap;

  const _AchievementLink({
    required this.unlocked,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : unlocked / total;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
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
              const Icon(Icons.emoji_events, color: Color(0xFFD81B60)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '전체 업적',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unlocked / $total 해제',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: Colors.black12,
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFFD81B60)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextScaleSelector extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _TextScaleSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = <double>[0.9, 1.0, 1.15, 1.3];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          const Row(
            children: [
              Icon(Icons.text_fields, color: AppColors.coral),
              SizedBox(width: 8),
              Text(
                '글자 크기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final opt in options)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _ScaleChip(
                      label: '${(opt * 100).round()}%',
                      selected: (value - opt).abs() < 0.001,
                      onTap: () => onChanged(opt),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScaleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ScaleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.coral : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
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
