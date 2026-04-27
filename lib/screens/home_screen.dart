import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/feature_unlocks.dart';
import '../models/booster.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../widgets/booster_shop_dialog.dart';
import '../widgets/gold_exchange_dialog.dart';
import '../widgets/main_sword_enhance_dialog.dart';
import '../widgets/main_sword_widget.dart';
import '../widgets/pass_expiry_banner.dart';
import '../widgets/dps_display.dart';
import '../widgets/floating_number.dart';
import '../widgets/feature_unlock_guide.dart';
import '../widgets/golden_slime.dart';
import '../widgets/gold_display.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<FloatingNumberData> _floats = [];
  final List<_SlimeSpawn> _slimes = [];
  int _nextId = 0;
  int _nextSlimeId = 0;
  final _rng = Random();

  void _handleTap(Offset globalPos) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPos);
    final result = ref.read(gameProvider.notifier).tapWithFeedback();
    final state = ref.read(gameProvider);
    if (state.haptic) {
      if (state.reduceTapHaptics) {
        if (result.isCrit) HapticFeedback.mediumImpact();
      } else if (result.isCrit) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
    if (state.sound) AudioService.instance.playTap();
    setState(() {
      _floats.add(FloatingNumberData(
        id: _nextId++,
        origin: local,
        amount: result.amount,
        isCrit: result.isCrit,
      ));
      if (result.slimeSpawned) _spawnSlime(box.size);
    });
  }

  void _removeFloat(int id) {
    if (!mounted) return;
    setState(() => _floats.removeWhere((f) => f.id == id));
  }

  void _spawnSlime(Size bounds) {
    final id = _nextSlimeId++;
    // Keep it clear of the top bar and the sword center by biasing the
    // random position toward the horizontal edges and avoiding the middle
    // band where the main sword sits.
    final w = bounds.width;
    final h = bounds.height;
    final leftSide = _rng.nextBool();
    final dx = leftSide
        ? 16.0 + _rng.nextDouble() * (w * 0.25)
        : w * 0.6 + _rng.nextDouble() * (w * 0.25) - 16.0;
    final dy = h * 0.25 + _rng.nextDouble() * (h * 0.45);
    _slimes.add(_SlimeSpawn(id: id, offset: Offset(dx, dy)));
  }

  void _defeatSlime(int id, Offset slimeOffset) {
    if (!mounted) return;
    final reward = ref.read(gameProvider.notifier).defeatGoldenSlime();
    if (ref.read(gameProvider).haptic) HapticFeedback.heavyImpact();
    setState(() {
      _slimes.removeWhere((s) => s.id == id);
      // Pop a big floating number where the slime was so the reward feels
      // grounded in the actual kill, not a phantom number from elsewhere.
      _floats.add(FloatingNumberData(
        id: _nextId++,
        origin: slimeOffset + const Offset(40, 30),
        amount: reward,
        isCrit: true,
      ));
    });
  }

  void _slimeTimedOut(int id) {
    if (!mounted) return;
    setState(() => _slimes.removeWhere((s) => s.id == id));
  }

  void _openBoosterShop() {
    showDialog<void>(
      context: context,
      builder: (_) => const BoosterShopDialog(),
    );
  }

  void _openGoldExchange() {
    showDialog<void>(
      context: context,
      builder: (_) => const GoldExchangeDialog(),
    );
  }

  void _openMainSwordEnhance() {
    showDialog<void>(
      context: context,
      builder: (_) => const MainSwordEnhanceDialog(),
    );
  }

  double _enhanceFabBottom(GameState game) {
    var bottom = 16.0;
    if (game.isFeatureUnlocked(FeatureUnlocks.boosterShop)) bottom += 60;
    if (game.isFeatureUnlocked(FeatureUnlocks.goldExchange)) bottom += 60;
    return bottom;
  }

  void _openUnlockRoadmap() {
    final game = ref.read(gameProvider);
    showFeatureUnlockRoadmapSheet(
      context,
      game: game,
      title: '홈 - 기능 로드맵',
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final slimeActive = _slimes.isNotEmpty;
    final lockedFeatures = lockedFeatureDefs(game);
    final nextLocked = nextRecommendedLockedFeature(game);

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: GoldDisplay(amount: game.gold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SlimeProgressBar(
                  remaining: game.tapsUntilSlime,
                  total: slimeSpawnEvery,
                  active: slimeActive,
                  reward: notifier.slimePreviewReward,
                ),
              ),
              const SizedBox(height: 10),
              DpsDisplay(dps: game.dps),
              const Spacer(),
              Center(
                child: MainSwordWidget(
                  onTap: _handleTap,
                  stage: game.mainSwordStage,
                ),
              ),
              const Spacer(),
              if (lockedFeatures.isNotEmpty && nextLocked != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _LockedFeaturePeekCard(
                    lockedCount: lockedFeatures.length,
                    def: nextLocked,
                    progress: nextLocked.progress(game),
                    onTap: _openUnlockRoadmap,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _BattleStatusPanel(
                  combo: game.combo,
                  tapPower: game.tapPower,
                  maxIdleReward: game.dps * offlineMaxSeconds,
                  idleHours: offlineMaxHours,
                  prestigeMultiplier: game.prestigeMultiplier,
                  collectionFraction: notifier.collectionBonusFraction,
                  boosters: game.activeBoosters,
                ),
              ),
              const SizedBox(height: 4),
              const PassExpiryBanner(),
              const SizedBox(height: 76),
            ],
          ),
          FloatingNumberLayer(items: _floats, onDone: _removeFloat),
          for (final slime in _slimes)
            Positioned(
              left: slime.offset.dx,
              top: slime.offset.dy,
              child: GoldenSlime(
                previewReward: notifier.slimePreviewReward,
                onDefeat: () => _defeatSlime(slime.id, slime.offset),
                onTimeout: () => _slimeTimedOut(slime.id),
              ),
            ),
          if (game.isFeatureUnlocked(FeatureUnlocks.boosterShop))
            Positioned(
              right: 16,
              bottom: 16,
              child: _ShopFab(onTap: _openBoosterShop),
            ),
          if (game.isFeatureUnlocked(FeatureUnlocks.goldExchange))
            Positioned(
              right: 16,
              bottom: game.isFeatureUnlocked(FeatureUnlocks.boosterShop)
                  ? 76
                  : 16,
              child: _ExchangeFab(onTap: _openGoldExchange),
            ),
          Positioned(
            right: 16,
            bottom: _enhanceFabBottom(game),
            child: _EnhanceFab(
              onTap: _openMainSwordEnhance,
              stage: game.mainSwordStage,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlimeSpawn {
  final int id;
  final Offset offset;
  const _SlimeSpawn({required this.id, required this.offset});
}

class _ShopFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ShopFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.coral,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.bolt, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _EnhanceFab extends StatelessWidget {
  final VoidCallback onTap;
  final int stage;
  const _EnhanceFab({required this.onTap, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF7C4DFF),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.auto_fix_high, color: Colors.white, size: 26),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$stage',
                    style: const TextStyle(
                      color: Color(0xFF7C4DFF),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExchangeFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ExchangeFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFB300),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.currency_exchange,
              color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _LockedFeaturePeekCard extends StatelessWidget {
  final int lockedCount;
  final FeatureUnlockDef def;
  final FeatureUnlockProgress progress;
  final VoidCallback onTap;

  const _LockedFeaturePeekCard({
    required this.lockedCount,
    required this.def,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: def.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(def.icon, size: 14, color: def.color),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '잠김 기능 $lockedCount개',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '다음 추천: ${def.label} · ${progress.progressText} (${progress.percentText})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.62),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 5,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation(def.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleStatusPanel extends StatelessWidget {
  final int combo;
  final double tapPower;
  final double maxIdleReward;
  final int idleHours;
  final double prestigeMultiplier;
  final double collectionFraction;
  final List<Booster> boosters;
  const _BattleStatusPanel({
    required this.combo,
    required this.tapPower,
    required this.maxIdleReward,
    required this.idleHours,
    required this.prestigeMultiplier,
    required this.collectionFraction,
    required this.boosters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final comboPct = (combo * comboBonusPerStack).clamp(0.0, 0.5) * 100;
    final permanentPct = ((prestigeMultiplier - 1) * 100).clamp(0.0, 9999999.0);
    final collectionPct = (collectionFraction * 100).clamp(0.0, 9999999.0);
    final now = DateTime.now();
    final activeBoosters = boosters.where((b) => b.isActive(now)).toList();
    Duration minRemaining = Duration.zero;
    double strongestBoost = 1.0;
    if (activeBoosters.isNotEmpty) {
      minRemaining = activeBoosters
          .map((b) => b.remaining(now))
          .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
      strongestBoost = activeBoosters
          .map((b) => b.multiplier)
          .fold<double>(1.0, (a, b) => a > b ? a : b);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkSurfaceAlt.withValues(alpha: 0.96),
                    AppColors.darkSurface.withValues(alpha: 0.96),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.98),
                    const Color(0xFFFFF3EA).withValues(alpha: 0.98),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize,
                      size: 14,
                      color: AppColors.deepCoral,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '전투 대시보드',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00695C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BattleMetricCard(
                    icon: Icons.touch_app,
                    title: '터치',
                    value: '+${NumberFormatter.formatPrecise(tapPower)}',
                    subtitle: '탭 1회 획득량',
                    color: const Color(0xFF8D6E00),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BattleMetricCard(
                    icon: Icons.nightlight_round,
                    title: '방치',
                    value: '+${NumberFormatter.format(maxIdleReward)}',
                    subtitle: '$idleHours시간 최대 누적',
                    color: const Color(0xFF5E35B1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _BattleMetricCard(
                    icon: Icons.auto_awesome,
                    title: '영구 배율',
                    value: '+${permanentPct.toStringAsFixed(0)}%',
                    subtitle: '환생 · 코인 상점',
                    color: const Color(0xFF00695C),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BattleMetricCard(
                    icon: Icons.collections_bookmark,
                    title: '수집 보너스',
                    value:
                        '+${collectionPct.toStringAsFixed(collectionFraction >= 1 ? 0 : 1)}%',
                    subtitle: '터치 · 동료 · 초월',
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
              ],
            ),
            if (combo > 1 || activeBoosters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '활성 효과',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                    if (combo > 1) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: AppColors.deepCoral, size: 15),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '콤보 x$combo',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '+${comboPct.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.deepCoral,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (combo / comboMax).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Colors.black
                              .withValues(alpha: isDark ? 0.28 : 0.12),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.coral),
                        ),
                      ),
                    ],
                    if (activeBoosters.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.bolt,
                              color: AppColors.deepCoral, size: 15),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '부스터 ${activeBoosters.length}개 · 최고 x${strongestBoost.toStringAsFixed(strongestBoost % 1 == 0 ? 0 : 1)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            _fmtDuration(minRemaining),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final b in activeBoosters.take(3))
                            _BoosterBadge(
                              label: _boosterLabel(b.type),
                              multiplier: b.multiplier,
                              remaining: b.remaining(now),
                            ),
                          if (activeBoosters.length > 3)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.24 : 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '+${activeBoosters.length - 3}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final totalSec = d.inSeconds.clamp(0, 1 << 31);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _boosterLabel(BoosterType type) {
    return switch (type) {
      BoosterType.dps => 'DPS',
      BoosterType.tap => '터치',
      BoosterType.rush => '러시',
      BoosterType.autoTap => 'AUTO',
    };
  }
}

class _BattleMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  const _BattleMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoosterBadge extends StatelessWidget {
  final String label;
  final double multiplier;
  final Duration remaining;
  const _BoosterBadge({
    required this.label,
    required this.multiplier,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final totalSec = remaining.inSeconds.clamp(0, 1 << 31);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    final timeText = '$m:${s.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.deepCoral.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.deepCoral.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label x${multiplier.toStringAsFixed(multiplier % 1 == 0 ? 0 : 1)} · $timeText',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.deepCoral,
        ),
      ),
    );
  }
}

/// Visible-from-anywhere progress bar for the next slime spawn. Replaces the
/// old text-only "슬라임까지 N회 터치" hint. While a slime is on screen, the
/// bar switches to an "출현 중!" call-to-action so the player knows it's the
/// active state, not a stuck progress meter.
class _SlimeProgressBar extends StatelessWidget {
  final int remaining;
  final int total;
  final bool active;
  final double reward;
  const _SlimeProgressBar({
    required this.remaining,
    required this.total,
    required this.active,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = active ? 1.0 : ((total - remaining) / total).clamp(0.0, 1.0);
    final accent = active ? const Color(0xFFE53935) : const Color(0xFFFFB300);
    final label = active
        ? '🟡 슬라임 출현! 처치 보상 +${NumberFormatter.format(reward)}'
        : '🟡 슬라임까지 $remaining회 · 처치 시 +${NumberFormatter.format(reward)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent.computeLuminance() < 0.5
                  ? accent
                  : const Color(0xFF8D6E00),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ),
    );
  }
}
