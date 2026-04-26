import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/achievement_catalog.dart';
import '../data/feature_unlocks.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../services/auth_service.dart';
import '../widgets/feature_unlock_guide.dart';
import '../widgets/onboarding_dialog.dart';
import 'achievement_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final authStatus = ref.watch(authStatusProvider);

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
          const _SectionTitle(title: '통계'),
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
                label: '누적 골드',
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
          const _SectionTitle(title: '업적'),
          const SizedBox(height: 8),
          _AchievementLink(
            unlocked: game.unlockedAchievements.length,
            total: achievementCatalog.length,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementScreen()),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: '해금 가이드'),
          const SizedBox(height: 8),
          _UnlockGuideHeader(
            game: game,
            onOpenRoadmap: () => showFeatureUnlockRoadmapSheet(
              context,
              game: game,
              title: '설정 - 해금 가이드',
            ),
            onReplayTutorial: () => showDialog<void>(
              context: context,
              builder: (_) => OnboardingDialog(
                game: game,
                replayMode: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FeatureUnlockRoadmapList(
            game: game,
            onTap: (def) => showFeatureUnlockDetailSheet(
              context,
              def: def,
              game: game,
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: '계정'),
          const SizedBox(height: 8),
          authStatus.when(
            data: (status) => _AccountCard(
              status: status,
              onRegister: () => _openAuthDialog(
                context,
                ref,
                initialMode: _AuthMode.register,
              ),
              onLogin: () => _openAuthDialog(
                context,
                ref,
                initialMode: _AuthMode.login,
              ),
              onLogout: () => _confirmLogout(context, ref),
            ),
            loading: () => const _AccountLoadingCard(),
            error: (_, __) => _AccountCard(
              status: const AuthStatus(
                userId: null,
                email: null,
                isAnonymous: true,
              ),
              onRegister: () => _openAuthDialog(
                context,
                ref,
                initialMode: _AuthMode.register,
              ),
              onLogin: () => _openAuthDialog(
                context,
                ref,
                initialMode: _AuthMode.login,
              ),
              onLogout: () => _confirmLogout(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: '설정'),
          const SizedBox(height: 8),
          _ToggleRow(
            icon: Icons.vibration,
            label: '진동 (터치 피드백)',
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
          const _SectionTitle(title: '데이터'),
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
                '시간 자동 설정 사용을 권장합니다.',
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
          '모든 진행도, 골드, 강화 레벨, 환생 코인, 통계가 삭제됩니다.\n'
          '이 작업은 되돌릴 수 없습니다.',
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

  Future<void> _openAuthDialog(
    BuildContext context,
    WidgetRef ref, {
    required _AuthMode initialMode,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AuthDialog(initialMode: initialMode),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('로그아웃할까요?'),
        content: const Text(
          '현재 기기의 진행도는 유지됩니다.\n'
          '로그아웃 후에는 게스트 상태로 계속 플레이합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await ref.read(authServiceProvider).signOutToGuest();
    await ref.read(gameProvider.notifier).persist();
    if (!context.mounted) return;
    _toast(context, result.message);
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

class _UnlockGuideHeader extends StatelessWidget {
  final GameState game;
  final VoidCallback onOpenRoadmap;
  final VoidCallback onReplayTutorial;

  const _UnlockGuideHeader({
    required this.game,
    required this.onOpenRoadmap,
    required this.onReplayTutorial,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = unlockedFeatureCount(game);
    final total = featureUnlockCatalog.length;
    final next = nextRecommendedLockedFeature(game);
    final nextProgress = next?.progress(game);
    final ratio = featureUnlockCompletionRatio(game);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.map_outlined, color: AppColors.deepCoral),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$unlocked / $total 기능 해금',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            next == null
                ? '모든 기능이 해금되었습니다.'
                : '다음 추천 목표: ${next.label} (${nextProgress?.percentText ?? '0%'})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation(AppColors.coral),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenRoadmap,
                icon: const Icon(Icons.visibility),
                label: const Text('전체 기준 보기'),
              ),
              OutlinedButton.icon(
                onPressed: onReplayTutorial,
                icon: const Icon(Icons.school),
                label: const Text('튜토리얼 다시 보기'),
              ),
            ],
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
                      '$unlocked / $total 해금',
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

class _AccountCard extends StatelessWidget {
  final AuthStatus status;
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const _AccountCard({
    required this.status,
    required this.onRegister,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final linked = status.isLinkedAccount;
    final title = linked ? (status.email ?? '로그인 계정') : '게스트 플레이 중';
    final subtitle =
        linked ? '클라우드 저장이 이 계정에 연결됩니다' : '계정을 만들면 현재 진행도를 이메일 계정에 연결합니다';

    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (linked ? Colors.teal : AppColors.coral)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  linked ? Icons.verified_user : Icons.person_outline,
                  color: linked ? Colors.teal.shade700 : AppColors.deepCoral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'ID ${status.shortUserId}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          if (linked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRegister,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('계정 만들기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onLogin,
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('로그인'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AccountLoadingCard extends StatelessWidget {
  const _AccountLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

enum _AuthMode { login, register }

class _AuthDialog extends ConsumerStatefulWidget {
  final _AuthMode initialMode;

  const _AuthDialog({required this.initialMode});

  @override
  ConsumerState<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends ConsumerState<_AuthDialog> {
  late _AuthMode _mode = widget.initialMode;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _mode == _AuthMode.register;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(isRegister ? '계정 만들기' : '로그인'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRegister
                  ? '현재 게스트 진행도를 이메일 계정에 연결합니다.'
                  : '클라우드 저장이 있으면 해당 계정 데이터를 불러옵니다.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: '이메일',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: '비밀번호',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon:
                      Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _mode =
                            isRegister ? _AuthMode.login : _AuthMode.register;
                      }),
              child: Text(isRegister ? '이미 계정이 있어요' : '새 계정 만들기'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isRegister ? '계정 만들기' : '로그인'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final service = ref.read(authServiceProvider);
    final game = ref.read(gameProvider.notifier);
    final isRegister = _mode == _AuthMode.register;
    final AuthActionResult result;
    try {
      if (isRegister) {
        result = await service.registerGuestAccount(
          email: _email.text,
          password: _password.text,
        );
        if (result.ok) await game.persist();
      } else {
        result = await service.signIn(
          email: _email.text,
          password: _password.text,
        );
        if (result.ok) {
          final loadedCloud = await game.loadCloudSaveForCurrentAccount();
          if (!mounted) return;
          _toast(
            context,
            loadedCloud ? '로그인 후 클라우드 저장을 불러왔어요' : result.message,
          );
          Navigator.pop(context);
          return;
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(context, '계정 처리 중 오류가 발생했어요');
      return;
    }

    if (!mounted) return;
    setState(() => _busy = false);
    _toast(context, result.message);
    if (result.ok) Navigator.pop(context);
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
        '데이터 초기화',
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

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
